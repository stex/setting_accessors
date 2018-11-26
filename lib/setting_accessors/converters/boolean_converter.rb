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
        else
          parse_other_value
        end
      end

      private

      #
      # Special handler for Rails 4.2, see the following deprecation warning:
      #
      # DEPRECATION WARNING: You attempted to assign a value which is not explicitly `true` or `false` (0.0)
      # to a boolean column. Currently this value casts to `false`.
      # This will change to match Ruby's semantics, and will cast to `true` in Rails 5.
      # If you would like to maintain the current behavior, you should explicitly handle
      # the values you would like cast to `false`.
      #
      def parse_other_value
        Gem.loaded_specs['activerecord'].version >= Gem::Version.create('5.0')
      end

      def parse_integer
        return true if value.to_i == 1
        return false if value.to_i.zero?

        nil
      end

      def parse_string
        case value.downcase
        when 'true', '1' then true
        when 'false', '0' then false
        when '' then nil
        else parse_other_value
        end
      end
    end
  end
end
