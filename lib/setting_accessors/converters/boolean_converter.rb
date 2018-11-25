# frozen_string_literal: true

module SettingAccessors
  module Converters
    class BooleanConverter < Base
      def parse_value
        case value
        when TrueClass, FalseClass
          value
        when String
          parse_string
        when Integer
          parse_integer
        end
      end

      private

      def parse_integer
        return true if value == 1
        return false if value.zero?

        nil
      end

      def parse_string
        case value.downcase
        when 'true', '1' then true
        when 'false', '0' then false
        end
      end
    end
  end
end
