require 'spec_helper'

describe Mongoid::Kms do

  it "encrypts the secure fields" do
    o = MyClass.new(secure: "batman", unsecure: "robin")
    o.save!

    expect(o.secure).to eq("batman")
    expect(o.kms_secure_secure).to_not be_nil
  end

  it "descripts the secure fields" do
    o = MyClass.new(unsecure: "robin", secure: "batman")
    o.save!

    o = MyClass.find(o.id)
    expect(o.secure).to eq("batman")
    expect(o.unsecure).to eq("robin")
  end

  it "encrypts the other fields" do
    o = OtherClass.new(unsecure: "pengiun", super_secure: "joker")
    o.save!

    o = OtherClass.find(o.id)
    expect(o.super_secure).to eq("joker")
    expect(o.unsecure).to eq("pengiun")
  end

  it "modifies the encryption if the context field changes" do
    o = MyClass.new(unsecure: "robin", secure: "other")
    o.save!

    o = MyClass.find(o.id)
    o.unsecure = "bla"
    o.save!

    o = MyClass.find(o.id)
    expect(o.secure).to eq("other")
  end

  it "updates properly" do
    o = MyClass.new(unsecure: "robin", secure: "other")
    o.save!

    o = MyClass.find(o.id)
    o.secure = 'salted-other'
    o.save!

    o = MyClass.find(o.id)
    expect(o.secure).to eq("salted-other")
  end

  it "handles a class without context" do
    o = MyClass.new(secure: "bla", unsecure: "blatoo")
    o.save!

    o = MyClass.find(o.id)
    expect(o.secure).to eq("bla")
  end

  it "fails to configure without a region" do
    expect{Mongoid::Kms.configure({region: "", key: ""})}.to raise_error(Mongoid::Kms::Errors::ConfigurationError, "Region and KMS id key are required.")
  end

  it "works with extended classes" do
    o = ExtendedClass.new(super_secure: "batman", unsecure: "robin", timestamp: Time.now, additional_secure: "wha!")
    o.save!

    o = ExtendedClass.find(o.id)
    expect(o.additional_secure).to eq("wha!")
    o.test_hash_crash
  end

  it "works fine with Mongoid + Hash" do
    class TestHashClass
      include Mongoid::Document
      include Mongoid::Kms

      secure_field "other", type: String, context: ["hammertime"]
      field :bla, type: Hash
    end

    o = TestHashClass.create!(bla: {name: "samson"})
    o = TestHashClass.find(o.id)
    o.bla
  end

end
