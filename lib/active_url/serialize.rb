require "yaml"

module ActiveUrl
  module Serialize
    def serialize(*attribute_names)
      attribute_names.flatten.compact.each do |attribute_name|
        getter_method_name = "#{attribute_name}_serialized"
        setter_method_name = "#{getter_method_name}="

        attribute getter_method_name

        define_method "#{attribute_name}=" do |value|
          if value.nil? then
            send setter_method_name, nil
          else
            send setter_method_name, value.to_yaml
          end
        end

        define_method attribute_name do
          result = send(getter_method_name)
          return nil if result.nil?
          YAML.load(result)
        end
      end
    end
  end
end
