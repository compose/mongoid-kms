require 'mongoid'
require 'byebug'

require_relative '../lib/mongoid/kms'

Mongoid.load!("spec/mongoid.yml", :test)

class MyClass
  include Mongoid::Document
  include Mongoid::Kms

  secure_field :secure, type: String, context: lambda { |d| {name: d.name} }
  field :unsecure

  def name
    @name ||= "me-#{Time.now.to_i}"
  end
end

Mongoid::Kms.configure({region: "us-east-1", key: ENV['AWS_KMS_KEY_ID']})
