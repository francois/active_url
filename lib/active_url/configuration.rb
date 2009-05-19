require 'singleton'

module ActiveUrl
  def self.config
    Configuration.instance
  end
  
  class Configuration
    include Singleton
    attr_accessor :secret
  end
end
