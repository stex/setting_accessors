# frozen_string_literal: true

module SettingAccessors
  module Converters
    class StringConverter < Base
      def parse_value
        value.to_s
      end
    end
  end
end
