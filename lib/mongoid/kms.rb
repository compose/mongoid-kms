require 'active_support/concern'
require 'aws-sdk'
require "mongoid/kms/version"

module Mongoid
  module Kms
    extend ActiveSupport::Concern

    included do
      class_attribute :kms_field_map
      self.kms_field_map ||= {}

      unless self.ancestors.include?(ActiveModel::Dirty)
        include ActiveModel::Dirty
      end
    end

    @configuration = {}
    @kms = nil

    # Module methods
    class << self
      def configure(args)
        if args[:region] && args[:region] != "" && args[:key] && args[:key] != ""
          @configuration = args
        else
          raise Errors::ConfigurationError.new("Region and KMS id key are required.")
        end
      end

      def configuration
        @configuration || {}
      end

      def kms
        @kms ||= Aws::KMS::Client.new(region: self.region)
      end

      def region
        configuration[:region]
      end

      def key
        configuration[:key]
      end

      def bson_class
        if defined? Moped::BSON
          Moped::BSON
        elsif defined? BSON
          BSON
        end
      end
    end

    # Instance methods
    def set_kms_values
      self.class.kms_field_map.each do |field_name, settings|
        if self.send("#{field_name}_changed?") || kms_context_value_changed?(field_name)
          encrypted_field_name = self.class.get_encrypted_field_name(field_name)

          if instance_variable_get("@#{field_name}").nil? && kms_context_value_changed?(field_name)
            value = self.class.decrypt_field(self, field_name, self.send(encrypted_field_name), self.class.kms_context_was(self, field_name))
          else
            value = send("#{field_name}")
          end

          if value.nil?
            self.send("#{encrypted_field_name}=", nil)
          else
            self.send("#{encrypted_field_name}=", self.class.encrypt_field(self, field_name, value))
          end
        end
      end
    end

    def kms_context_value_changed?(field_name)
      self.class.kms_context_array(self, field_name).find { |f| self.respond_to?(f) && self.respond_to?("#{f}_changed?") && self.send("#{f}_changed?") }
    end

    # Class methods
    module ClassMethods
      def inherited(child)
        child.kms_field_map = self.kms_field_map.clone

        child.kms_field_map.each do |field_name, args|
          child.add_secure_field(field_name, args)
        end
      end

      def add_secure_field(field_name, args)
        encrypted_field_name = get_encrypted_field_name(field_name)

        define_attribute_methods field_name.to_sym
        before_save :set_kms_values

        kms_field_map[field_name.to_s] = {context: args.delete(:context), type: args[:type]}

        field encrypted_field_name, type: Mongoid::Kms.bson_class::Binary

        self.class_eval do
          define_method(field_name) do
            instance_variable_get("@#{field_name}") || begin
              raw = send("kms_secure_#{field_name}")

              if raw.nil?
                raw
              else
                v = self.class.decrypt_field(self, field_name, raw)
                instance_variable_set("@#{field_name}", v)
                v
              end
            end
          end

          define_method("#{field_name}=") do |value|
            self.send("#{field_name}_will_change!")
            instance_variable_set("@#{field_name}", value)
          end
        end
      end


      def encrypt_field(object, field_name, value)
        Mongoid::Kms.kms.encrypt({
          key_id: Mongoid::Kms.key,
          plaintext: value,
          encryption_context: kms_context(object, field_name)
        })[:ciphertext_blob].force_encoding('UTF-8')
      end

      def decrypt_field(object, field_name, data, encryption_context = nil)
        encryption_context ||= kms_context(object, field_name)

        Mongoid::Kms.kms.decrypt({
          ciphertext_blob: data,
          encryption_context: encryption_context
        })[:plaintext]
      end

      def kms_context(object, field_name)
        kms_context_array(object, field_name).inject({}) do |hash, key|
          if object.respond_to?(key)
            value = object.send(key).to_s
            hash[key] = value if !value.nil? && value != ""
          else
            hash[key] = key
          end

          hash
        end
      end

      def kms_context_was(object, field_name)
        kms_context_array(object, field_name).inject({}) do |hash, key|
          if object.respond_to?("#{key}_was") && object.send("#{key}_changed?")
            hash[key] = object.send("#{key}_was").to_s
          elsif object.respond_to?(key)
            hash[key] = object.send(key).to_s
          else
            hash[key] = key
          end

          hash
        end
      end

      def kms_context_array(object, field_name)
        kms_field_map[field_name.to_s][:context] || []
      end

      def kms_type(field_name)
        kms_field_map[field_name.to_s][:type]
      end

      def get_encrypted_field_name(field_name)
        "kms_secure_#{field_name}"
      end

      def secure_field(field_name, args)
        add_secure_field(field_name, args)
      end
    end

    module Errors
      class ConfigurationError < RuntimeError; end
    end
  end
end
