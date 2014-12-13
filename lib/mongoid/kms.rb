require 'active_support/concern'
require 'aws-sdk'
require "mongoid/kms/version"

module Mongoid
  module Kms
    extend ActiveSupport::Concern

    @configuration = {}
    @kms = nil

    def self.configure(args)
      @configuration = args
    end

    def self.configuration
      @configuration || {}
    end

    def self.kms
      @kms ||= Aws::KMS::Client.new(region: self.region)
    end

    def self.region
      configuration[:region]
    end

    def self.key
      configuration[:key]
    end

    def self.bson_class
      if defined? Moped::BSON
        Moped::BSON
      elsif defined? BSON
        BSON
      end
    end

    module ClassMethods
      def encrypt_field(object, field_name, value)
        Mongoid::Kms.kms.encrypt({
          key_id: Mongoid::Kms.key,
          plaintext: value,
          encryption_context: kms_context(object, field_name)
        })[:ciphertext_blob].force_encoding('UTF-8')
      rescue ArgumentError
        raise "Error using KMS context.  If you use an object's field for context, set your encrypted fields explicitly: myobject.#{field_name} = #{value.inspect}"
      end

      def decrypt_field(object, field_name, data)
        Mongoid::Kms.kms.decrypt({
          ciphertext_blob: data,
          encryption_context: kms_context(object, field_name)
        })[:plaintext]
      end

      def kms_context(object, field_name)
        c = @kms_field_map[field_name.to_s][:context]
        c = c.call(object) if c.is_a?(Proc)
        c
      end

      def kms_type(field_name)
        @kms_field_map[field_name.to_s][:type]
      end

      def secure_field(field_name, args)
        encrypted_field_name = "kms_secure_#{field_name}"

        @kms_field_map ||= {}
        @kms_field_map[field_name.to_s] = {context: args.delete(:context), type: args.delete(:type)}

        field encrypted_field_name, args.merge(type: Mongoid::Kms.bson_class::Binary)

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
          instance_variable_set("@#{field_name}", value)

          if value.nil?
            self.send("#{encrypted_field_name}=", nil)
          else
            self.send("#{encrypted_field_name}=", self.class.encrypt_field(self, field_name, value))
          end
        end
      end
    end
  end
end
