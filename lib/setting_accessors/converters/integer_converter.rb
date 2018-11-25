# frozen_string_literal: true

module SettingAccessors
  module Converters
    class IntegerConverter < Base
      def parse_value
        value.to_i
      end
    end
  end
end
