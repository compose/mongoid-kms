require 'active_support/concern'
require 'aws-sdk'
require "mongoid/kms/version"

module Mongoid
  module Kms
    extend ActiveSupport::Concern

    included do
      class_attribute :kms_field_map
      self.kms_field_map ||= {}
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

      def binary_factory(data)
        if defined? Moped::BSON
          Moped::BSON::Binary.new(:generic, data)
        elsif defined? BSON
          BSON::Binary.new(data)
        end
      end
    end

    # Instance methods
    def set_kms_values
      self.class.kms_field_map.each do |field_name, settings|
        if self.new_record? || # always run new records through this
            changed_attributes.keys.include?(field_name.to_sym) || # this is a hack to get around Mongoid's weakass dirty hack
            kms_context_value_changed?(field_name) # checks if any of the context fields have changed
          encrypted_field_name = self.class.get_encrypted_field_name(field_name)

          if !instance_variable_defined?("@#{field_name}") && kms_context_value_changed?(field_name)
            raw = self.send(encrypted_field_name)
            raw = raw.data if raw.is_a?(Mongoid::Kms.bson_class::Binary)
            value = self.class.decrypt_field(self, field_name, raw, self.class.kms_context_was(self, field_name))
          else
            value = send("#{field_name}")
          end

          if value.nil? || value == ""
            self.send("#{encrypted_field_name}=", nil)
          else
            self.send("#{encrypted_field_name}=", Mongoid::Kms.binary_factory(self.class.encrypt_field(self, field_name, value)))
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
        super(child)
      end

      def encrypt_field(object, field_name, value)
        Mongoid::Kms.kms.encrypt({
          key_id: Mongoid::Kms.key,
          plaintext: value,
          encryption_context: kms_context(object, field_name)
        })[:ciphertext_blob]
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
        encrypted_field_name = get_encrypted_field_name(field_name)

        create_dirty_methods field_name, field_name
        after_validation :set_kms_values

        kms_field_map[field_name.to_s] = {context: args.delete(:context), type: args[:type]}

        field encrypted_field_name, type: Mongoid::Kms.bson_class::Binary

        define_method(field_name) do
          if instance_variable_defined?("@#{field_name}")
            instance_variable_get("@#{field_name}")
          else
            raw = send("kms_secure_#{field_name}")
            raw = raw.data if raw.is_a?(Mongoid::Kms.bson_class::Binary)

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

    module Errors
      class ConfigurationError < RuntimeError; end
    end
  end
end
