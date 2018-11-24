# frozen_string_literal: true

#
# This class hopefully will hopefully one day mimic ActiveRecord's
# attribute assigning methods, meaning that a conversion to the column type
# is done as soon as a new value is assigned by the programmer.
#
# If the value cannot be parsed in the required type, +nil+ is assigned.
# Please make sure that you specify the correct validations in settings.yml
# or assigned model to avoid this.
#
# Currently supported types:
#   - Fixnum
#   - String
#   - Boolean
#
# If the type is 'polymorphic', it is not converted at all.
#
module SettingAccessors
  class Converter

    def initialize(value_type)
      @value_type = value_type
    end

    #
    # Converts the setting's value to the correct type
    #
    def convert(new_value)
      # If the value is set to be polymorphic, we don't have to convert anything.
      return new_value if @value_type.to_s == 'polymorphic'

      # ActiveRecord only converts non-nil values to their database type
      # during assignment
      return new_value if new_value.nil?

      parse_method = :"parse_#{@value_type}"

      if private_methods.include?(parse_method)
        send(parse_method, new_value)
      else
        Rails.logger.warn("Invalid Setting type: #{@value_type}")
        new_value
      end
    end

    private

    def parse_boolean(value)
      case value
      when TrueClass, FalseClass
        value
      when String
        return true if %w[true 1].include?(value.downcase)
        return false if %w[false 0].include?(value.downcase)
        nil
      when Fixnum
        return true if value == 1
        return false if value.zero?
        nil
      else
        nil
      end
    end

    def parse_integer(value)
      value.to_i
    end

    def parse_string(value)
      value.to_s
    end
  end
end
