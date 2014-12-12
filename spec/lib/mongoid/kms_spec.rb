require 'spec_helper'

describe Mongoid::Kms do

  it "encrypts the secure fields" do
    o = MyClass.new(secure: "batman", unsecure: "robin")
    o.save!

    expect(o.secure).to eq("batman")
    expect(o.kms_secure_secure).to_not be_nil
  end

  it "descripts the secure fields" do
    o = MyClass.new(secure: "batman", unsecure: "robin")
    o.save!

    o = MyClass.find(o.id)
    byebug
    expect(o.secure).to eq("batman")
    expect(o.unsecure).to eq("robin")
  end

end
