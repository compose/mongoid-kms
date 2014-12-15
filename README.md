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
require 'mongoid/kms'

Mongoid::Kms.configure({region: "us-east-1", key: "your aws kms key id i.e <02342-234-232-234-234>"})
```

When defining your classes, `include Mongoid::Kms`, and use the
`secure_field` to define your fields.  The `:context` argument is an
optional list of method names or strings used for encrypting your
values.

The context argument is an important way to ensure simply having the
authentication keys and data field does not enable decryption.  When
using context, it also requires an attacker to know the decryption
context.

```ruby
class MyClass
  include Mongoid::Document
  include Mongoid::Kms

  secure_field :my_secure_field, type: String, context: [:unsecure_field, "some-string"]
  field :unsecure_field
end
```

## Development and Testing

In development or testing, just require `mongoid/kms/mock` and the
package will use Rot13 for encryption.
