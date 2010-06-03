require 'spec_helper'

describe ActiveUrl do
  before(:each) do
    ActiveUrl::Config.stub!(:secret).and_return("secret")
  end

  context "instance with serialize" do
    before(:all) do
      class ::Secret < ActiveUrl::Base
        serialize :serialized_value
      end
    end

    after(:all) do
      Object.send(:remove_const, "Secret")
    end

    before(:each) do
      @url = Secret.new
    end

    it "should return an equivalent object when found" do
      @url.serialized_value= {:a => "b"}
      @url.save
      Secret.find(@url.id).serialized_value.should == {:a => "b"}
    end

    it "should accept to serialize nil" do
      @url.serialized_value= nil
      @url.save
      Secret.find(@url.id).serialized_value.should be_nil
    end

    it "should be nil by default" do
      @url.serialized_value.should be_nil
      @url.save
      Secret.find(@url.id).serialized_value.should be_nil
    end
  end
end
