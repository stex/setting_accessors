# frozen_string_literal: true

module SettingAccessors
  module Converters
    class Base
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def convert
        # ActiveRecord does not convert +nil+ values to the corresponding database type
        return value if value.nil?

        parse_value
      end

      def self.parse_value
        raise NotImplementedError
      end
    end
  end
end
