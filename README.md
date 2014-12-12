# Mongoid::Kms

Easily encrypt your datas using AWS's KSM.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mongoid-kms'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mongoid-kms

## Usage

Environmental variables to include:

```
AWS_ACCESS_KEY_ID # an IAM access key
AWS_SECRET_ACCESS_KEY # an IAM access secret
```

Somewhere before your run your application, you will need to add this:

```ruby
Mongoid::Kms.configure({region: "us-east-1", key: "your aws kms key id i.e <02342-234-232-234-234>"})
```

When defining yoru classes, `include Mongoid::Kms`, and use the
`secure_field` to define your fields with a required `:context`.
Context must return a hash.

```ruby
class MyClass
  include Mongoid::Document
  include Mongoid::Kms

  secure_field :secure, type: String, context: lambda { |d| {name: d.name} }
  field :unsecure

  def name
    @name ||= "me-#{Time.now.to_i}"
  end
end
```
