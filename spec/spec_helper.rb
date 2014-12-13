require 'mongoid'
require 'byebug'

require_relative '../lib/mongoid/kms'

Mongoid.load!("spec/mongoid.yml", :test)

class MyClass
  include Mongoid::Document
  include Mongoid::Kms

  secure_field :secure, type: String, context: lambda { |d| {name: d.unsecure} }
  field :unsecure
end

class OtherClass
  include Mongoid::Document
  include Mongoid::Kms

  secure_field :super_secure, type: String, context: lambda { |d| {some_name: d.unsecure} }
  field :unsecure
end


Mongoid::Kms.configure({region: "us-east-1", key: ENV['AWS_KMS_KEY_ID']})
