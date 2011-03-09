module ActiveUrl
  module Callbacks
    def save_with_callbacks
      save_without_callbacks.tap do |result|
        run_callbacks(:after_save) if result
      end
    end
    
    def self.included(base)
      base.class_eval do
        include ActiveSupport::Callbacks # Already included by ActiveRecord.
        alias_method_chain :save, :callbacks
        define_callbacks :after_save
      end
    end
  end
end
