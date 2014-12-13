require 'spec_helper'

describe Mongoid::Kms do

  it "encrypts the secure fields" do
    o = MyClass.new(unsecure: "robin")
    o.secure = "batman"
    o.save!

    expect(o.secure).to eq("batman")
    expect(o.kms_secure_secure).to_not be_nil
  end

  it "descripts the secure fields" do
    o = MyClass.new(unsecure: "robin")
    o.secure = "batman"
    o.save!

    o = MyClass.find(o.id)
    expect(o.secure).to eq("batman")
    expect(o.unsecure).to eq("robin")
  end

  it "encrypts teh other fields" do
    o = OtherClass.new(unsecure: "pengiun")
    o.super_secure = "joker"
    o.save!

    o = OtherClass.find(o.id)
    expect(o.super_secure).to eq("joker")
    expect(o.unsecure).to eq("pengiun")
  end

end
