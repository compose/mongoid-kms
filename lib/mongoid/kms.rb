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
      def encrypt_field(field_name, value)
        Mongoid::Kms.kms.encrypt({
          key_id: Mongoid::Kms.key,
          plaintext: value,
          encryption_context: kms_context(field_name)
        })[:ciphertext_blob].force_encoding('UTF-8')
      end

      def decrypt_field(field_name, data)
        Mongoid::Kms.kms.decrypt({
          ciphertext_blob: data,
          encryption_context: kms_context(field_name)
        })[:plaintext]
      end

      def kms_context(field_name)
        c = @ksm_field_map[field_name.to_s][:context]
        c = c.call(self) if c.is_a?(Proc)
        c
      end

      def ksm_type(field_name)
        @ksm_field_map[field_name.to_s][:type]
      end

      def secure_field(field_name, args)
        encrypted_field_name = "kms_secure_#{field_name}"

        @ksm_field_map ||= {}
        @ksm_field_map[field_name.to_s] = {context: args.delete(:context), type: args.delete(:type)}

        field encrypted_field_name, args.merge(type: Mongoid::Kms.bson_class::Binary)

        define_method(field_name) do
          instance_variable_get("@#{field_name}") || begin
          v = self.class.decrypt_field(field_name, send("kms_secure_#{field_name}"))
            instance_variable_set("@#{field_name}", v)
            v
          end
        end

        define_method("#{field_name}=") do |value|
          instance_variable_set("@#{field_name}", value)
          self.send("#{encrypted_field_name}=", self.class.encrypt_field(field_name, value))
        end
      end
    end
  end
end
