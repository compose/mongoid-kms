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

  it "handles a class without context" do
    o = MyClass.new(secure: "bla", unsecure: "blatoo")
    o.save!

    o = MyClass.find(o.id)
    expect(o.secure).to eq("bla")
  end

end
