# frozen_string_literal: true

module SettingAccessors
  module Converters
    class PolymorphicConverter < Base
      def parse_value
        value
      end
    end
  end
end
