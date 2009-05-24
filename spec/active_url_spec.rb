require 'spec_helper'

describe ActiveUrl do
  before(:each) do
    ActiveUrl::Config.stub!(:secret).and_return("secret")
  end
  
  context "instance" do
    before(:each) do
      @url = ActiveUrl::Base.new
    end
    
    it "should have nil id" do
      @url.id.should be_nil
    end
  
    it "should be a new_record" do
      @url.should be_new_record
    end
    
    it "should be saveable" do
      @url.save.should be_true
    end
  
    context "after saving" do
      before(:each) do
        @url.save
      end
    
      it "should have an id" do
        @url.id.should_not be_blank
      end
      
      it "should not be a new record" do
        @url.should_not be_new_record
      end
    end
  end
  
  context "derived" do
    before(:all) do  
      class DerivedClass < ActiveUrl::Base
        attribute :foo, :bar
        attribute :baz, :accessible => true
        attr_accessible :bar
          
        attr_accessor :x, :y
        attr_accessible :y
      end
    end
    
    context "instance" do
      it "should not mass-assign attributes by default" do
        @url = DerivedClass.new(:foo => "foo")
        @url.foo.should be_nil
      end
    
      it "should mass-assign attributes declared as attr_accessible" do
        @url = DerivedClass.new(:bar => "bar")
        @url.bar.should == "bar"
      end
    
      it "should mass-assigned attributes with :accessible specified on declaration" do
        @url = DerivedClass.new(:baz => "baz")
        @url.baz.should == "baz"
      end

      it "should not mass-assign virtual attributes by default" do
        @url = DerivedClass.new(:x => "x")
        @url.x.should be_nil
      end
    
      it "should mass-assign its accessible virtual attributes" do
        @url = DerivedClass.new(:y => "y")
        @url.y.should == "y"
      end
      
      it "should know its mass-assignable attribute names" do
        @url = DerivedClass.new
        [ :bar, :baz, :y ].each { |name| @url.accessible_attributes.should     include(name) }
        [ :foo, :x       ].each { |name| @url.accessible_attributes.should_not include(name) }
      end
      
      it "should know its attribute names" do
        @url = DerivedClass.new
        [ :foo, :bar, :baz ].each { |name| @url.attribute_names.should     include(name) }
        [ :x, :y           ].each { |name| @url.attribute_names.should_not include(name) }
      end
      
      context "equality" do
        before(:all) do
          class OtherClass < DerivedClass
          end
        end
        
        it "should be based on class and attributes only" do
          @url  = DerivedClass.new(:bar => "bar", :baz => "baz")
          @url2 = DerivedClass.new(:bar => "bar", :baz => "baz")
          @url3 = DerivedClass.new(:bar => "BAR", :baz => "baz")
          @url4 =   OtherClass.new(:bar => "bar", :baz => "baz")
          @url.should == @url2
          @url.should_not == @url3
          @url.should_not == @url4
        end
      end
    end
    
    context "class" do
      it "should know its mass-assignable attribute names" do
        [ :bar, :baz, :y ].each { |name| DerivedClass.accessible_attributes.should     include(name) }
        [ :foo, :x       ].each { |name| DerivedClass.accessible_attributes.should_not include(name) }
      end
      
      it "should know its attribute names" do
        [ :foo, :bar, :baz ].each { |name| DerivedClass.attribute_names.should     include(name) }
        [ :x, :y           ].each { |name| DerivedClass.attribute_names.should_not include(name) }
      end
    end
  end
  
  context "instance with validations" do
    before(:all) do
      class Registration < ActiveUrl::Base  
        attribute :name, :email, :password, :age, :accessible => true
        validates_presence_of :name
        validates_format_of :email, :with => /^[\w\.=-]+@[\w\.-]+\.[a-zA-Z]{2,4}$/ix
        validates_length_of :password, :minimum => 8
        validates_numericality_of :age
        after_save :send_registration_email
      
        def send_registration_email
          @sent = true
        end
      end
    end
    
    context "when invalid" do
      before(:each) do
        @registration = Registration.new(:email => "user @ example . com", :password => "short", :age => "ten")
      end
      
      it "should not validate" do
        @registration.should_not be_valid
      end
  
      it "should not save" do
        @registration.save.should_not be_true
        @registration.id.should be_nil
      end

      it "should raise ActiveUrl::InvalidRecord when saved with bang" do
        lambda { @registration.save! }.should raise_error(ActiveUrl::RecordInvalid)
      end
      
      context "and saved" do
        before(:each) do
          @registration.save
        end

        it "should have errors" do
          @registration.errors.should_not be_empty
        end
        
        it "should validate presence of an attribute" do
          @registration.errors[:name].should_not be_blank
        end
        
        it "should validate format of an attribute" do
          @registration.errors[:email].should_not be_blank
        end
        
        it "should validate length of an attribute" do
          @registration.errors[:password].should_not be_nil
        end
        
        it "should validate numericality of an attribute" do
          @registration.errors[:age].should_not be_nil
        end
        
        it "should not execute any after_save callbacks" do
          @registration.instance_variables.should_not include("@sent")
        end
      end
    end
    
    context "when valid" do
      before(:each) do
        @registration = Registration.new(:name => "John Doe", :email => "user@example.com", :password => "password", :age => "10")
      end
      
      it "should validate" do
        @registration.should be_valid
      end
      
      context "and saved" do
        before(:each) do
          @registration.save
        end
        
        it "should have an id" do
          @registration.id.should_not be_blank
        end
        
        it "should have a param equal to its id" do
          @registration.id.should == @registration.to_param
        end
        
        it "should execute any after_save callbacks" do
          @registration.instance_variables.should include("@sent")
        end
        
        context "and re-found by its class" do
          before(:each) do
            @found = Registration.find(@registration.id)
          end
          
          it "should exist" do
            @found.should_not be_nil
          end
          
          it "should have the same id" do
            @found.id.should == @registration.id
          end
          
          it "should have the same attributes" do
            @found.attributes.should == @registration.attributes
          end
          
          it "should be valid" do
            @found.should be_valid
          end
        end
        
        context "and subsequently made invalid" do
          before(:each) do
            @registration.password = "short"
            @registration.stub!(:valid?).and_return(true)
            @registration.save
          end
                              
          it "should not be found by its class" do
            @registration.id.should_not be_blank
            lambda { Registration.find(@registration.id) }.should raise_error(ActiveUrl::RecordNotFound)
          end
        end
      end
    end
    
    it "should raise ActiveUrl::RecordNotFound if id does not exist" do
      lambda { Registration.find("blah") }.should raise_error(ActiveUrl::RecordNotFound)
    end
  end
  
  context "instance with belongs_to association" do
    before(:all) do    
      # a simple pretend-ActiveRecord model for testing belongs_to without setting up a db:
      class ::User < ActiveRecord::Base
        def self.columns() @columns ||= []; end
        def self.column(name, sql_type = nil, default = nil, null = true)
          columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
        end
      end
    
      class Secret < ActiveUrl::Base
        belongs_to :user
      end
    end
    
    before(:each) do
      @url = Secret.new
      @user = User.new
      @user.stub!(:id).and_return(1)
    end
    
    it "should raise ArgumentError if the association name is not an ActiveRecord class" do
      lambda { Secret.belongs_to :foo }.should raise_error(ArgumentError)
    end
    
    it "should respond to association_id, association_id=, association & association=" do
      @url.attribute_names.should include(:user_id)
      @url.should respond_to(:user)
      @url.should respond_to(:user=)
    end
    
    it "should have nil association if association or association_id not set" do
      @url.user.should be_nil
    end
    
    it "should not allow mass assignment of association_id" do
      @url = Secret.new(:user_id => @user.id)
      @url.user_id.should be_nil
      @url.user.should be_nil
    end
    
    it "should not allow mass assignment of association" do
      @url = Secret.new(:user => @user)
      @url.user_id.should be_nil
      @url.user.should be_nil
    end
    
    it "should be able to have its association set to nil" do
      @url.user_id = @user.id
      @url.user = nil
      @url.user_id.should be_nil
    end
    
    it "should raise ArgumentError if association is set to wrong type" do
      lambda { @url.user = Object.new }.should raise_error(TypeError)
    end
      
    it "should find its association_id if association is set" do
      @url.user = @user
      @url.user_id.should == @user.id
    end
    
    it "should find its association if association_id is set" do
      User.should_receive(:find).with(@user.id).and_return(@user)
      @url.user_id = @user.id
      @url.user.should == @user
    end
    
    it "should return nil association if association_id is unknown" do
      User.should_receive(:find).and_raise(ActiveRecord::RecordNotFound)
      @url.user_id = 10
      @url.user.should be_nil
    end
    
    it "should know its association when found by id" do
      User.should_receive(:find).with(@user.id).and_return(@user)
      @url.user_id = @user.id
      @url.save
      @found = Secret.find(@url.id)
      @found.user.should == @user
    end

  end

  describe "crypto" do
    it "should raise ArgumentError when no secret is set" do
      ActiveUrl::Config.stub!(:secret).and_return(nil)
      lambda { ActiveUrl::Crypto.encrypt("clear") }.should raise_error(ArgumentError)
    end
  
    it "should decode what it encodes" do
      ActiveUrl::Crypto.decrypt(ActiveUrl::Crypto.encrypt("clear")).should == "clear"
    end
  
    it "should always yield URL-safe output characters" do
      url_safe = /^[\w\-]*$/
      (1..20).each do |n|
        clear = (0...8).inject("") { |string, n| string << rand(255).chr } # random string
        cipher = ActiveUrl::Crypto.encrypt(clear)
        cipher.should =~ url_safe
      end
    end
  end
end
