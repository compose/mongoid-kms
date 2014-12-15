require 'mongoid'
require 'byebug'

require_relative '../lib/mongoid/kms'

Mongoid.load!("spec/mongoid.yml", :test)

class MyClass
  include Mongoid::Document
  include Mongoid::Kms

  secure_field :secure, type: String, context: [:unsecure]
  field :unsecure
end

class OtherClass
  include Mongoid::Document
  include Mongoid::Kms

  secure_field :super_secure, type: String, context: [:unsecure, "deployment"]
  field :unsecure
end

class ClassWithoutContext
  include Mongoid::Document
  include Mongoid::Kms

  secure_field :secure, type: String
  field :unsecure
end

Mongoid::Kms.configure({region: "us-east-1", key: ENV['AWS_KMS_KEY_ID']})
