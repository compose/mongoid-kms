require 'mongoid/kms'

module Mongoid
  module Kms
    module ClassMethods
      def encrypt_field(object, field_name, value)
        Rot13.rotate(value, 13)
      end

      def decrypt_field(object, field_name, data, encryption_context = nil)
        Rot13.rotate(data, -13)
      end
    end

    # inline Rot13 gem, as seen in
    # https://github.com/jrobertson/rot13/blob/012c9c37d767a364f793db00890dee82d9a65732/lib/rot13.rb
    # so we don't add unnecessary dependencies
    class Rot13
      def self.rotate(s,deg=13)
        a = ('a'..'z').map.with_index{|x,i| [x.chr,i] }

        r = s.split(//).map do |x|
          item = a.assoc(x.downcase)
          c = item ? a.rotate(deg)[item.last].first : x
          x == x.downcase ? c : c.upcase
        end
        r.join
      end
    end
  end
end
