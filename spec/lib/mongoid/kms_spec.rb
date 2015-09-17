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

  it "ingores nil on create" do
    o = MyClass.new(unsecure: "robin", secure: nil)
    o.save!

    o = MyClass.find(o.id)
    expect(o.secure).to be_nil
    expect(o.unsecure).to eq("robin")
  end

  it "ingores empty string on create" do
    o = MyClass.new(unsecure: "robin", secure: "")
    o.save!

    o = MyClass.find(o.id)
    expect(o.secure).to be_nil
    expect(o.unsecure).to eq("robin")
  end

  it "sets nil on update" do
    o = MyClass.new(unsecure: "robin", secure: "old-secure-value")
    o.save!

    o.update_attributes!(secure: nil)

    o = MyClass.find(o.id)
    expect(o.secure).to be_nil
    expect(o.unsecure).to eq("robin")
  end

  it "sets empty string on update" do
    o = MyClass.new(unsecure: "robin", secure: "old-secure-value")
    o.save!

    o.secure = ""
    o.save!

    o = MyClass.find(o.id)
    expect(o.secure).to be_nil
    expect(o.unsecure).to eq("robin")
  end

  it "udpates nil values properly" do
    o = MyClass.new(unsecure: "robin", secure: nil)
    o.save!

    o.secure = "batman"
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

  describe "works with embedded documents" do
    before do
      class ParentClass
        include Mongoid::Document

        embeds_one :child_class, class_name: "ChildClass"

        field :unsecure, type: String
      end

      class ChildClass
        include Mongoid::Document
        include Mongoid::Kms

        embedded_in :parent_class

        secure_field :secure, type: String
        field :unsecure, type: String
      end
    end

    it "on save" do
      o = ParentClass.create!(unsecure: "wonder woman")
      o.child_class = ChildClass.new(secure: "invisible ship", unsecure: "a whip")
      o.save!

      o.reload
      expect(o.unsecure).to eq("wonder woman")
      expect(o.child_class.secure).to eq("invisible ship")
      expect(o.child_class.unsecure).to eq("a whip")
    end

    it "on create" do
      o = ParentClass.create!(unsecure: "wonder woman", child_class: ChildClass.new(secure: "invisible ship", unsecure: "a whip"))
      o.reload

      expect(o.unsecure).to eq("wonder woman")
      expect(o.child_class.secure).to eq("invisible ship")
      expect(o.child_class.unsecure).to eq("a whip")
    end
  end

end
