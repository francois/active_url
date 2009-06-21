require 'spec_helper'

describe ActiveUrl do
  before(:each) do
    ActiveUrl::Config.stub!(:secret).and_return("secret")
  end

  context "instance with callbacks" do
    before(:all) do
      class ::Registration < ActiveUrl::Base  
        attribute :email
        after_save :send_registration_email
      end
    end
    
    after(:all) do
      Object.send(:remove_const, "Registration")
    end
    
    before(:each) do
      @registration = Registration.new(:email => "email@example.com")
      @registration.stub!(:valid?).and_return(true)
    end
    
    it "should not run the callback when saved if the instance is invalid" do
      @registration.stub!(:valid?).and_return(false)
      @registration.should_not_receive(:send_registration_email)
      @registration.save
    end
    
    it "should run the callback when saved if the instance is valid" do
      @registration.should_receive(:send_registration_email)
      @registration.save
    end
    
    it "should not run the callback when found from its ID" do
      @registration.stub!(:send_registration_email).and_return(true)
      @registration.save
      @found = Registration.new
      Registration.should_receive(:new).and_return(@found)
      @found.should_not_receive(:send_registration_email)
      Registration.find(@registration.id)
    end
  end
end