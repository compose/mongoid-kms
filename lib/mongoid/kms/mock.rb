require 'mongoid/kms'
require 'rot13'

module Mongoid
  module Kms
    module ClassMethods
      def encrypt_field(object, field_name, value)
        Rot13.rotate(value, 13)
      end

      def decrypt_field(object, field_name, data)
        Rot13.rotate(data, -13)
      end
    end
  end
end
