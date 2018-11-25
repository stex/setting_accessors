# frozen_string_literal: true

module SettingAccessors
  module Converters
    class IntegerConverter < Base
      def parse_value
        return parse_boolean if value == true || value == false

        value.to_i
      rescue NoMethodError
        nil
      end

      private

      def parse_boolean
        value ? 1 : 0
      end
    end
  end
end
