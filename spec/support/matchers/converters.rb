# frozen_string_literal: true

#
# Specialized matcher to test whether a Converter processes its inputs correctly.
# It can either test for a given expected value or compare the result
# to ActiveRecord's internal mechanisms.
# Please note that the latter may differ between database adapters, so use with care.
#
# @example
#   expect(SettingAccessors::Converters::StringConverter).to convert(1).to('1')
#
# @example Test whether the converter produces the same output as ActiveRecord
#   expect(SettingAccessors::Converters::StringConverter).to convert(1).similar_to(User.first).on(:first_name)
#
RSpec::Matchers.define :convert do |value|
  match do |converter_class|
    @errors         = []
    converter       = converter_class.new(value)
    converted_value = converter.convert

    unless instance_variable_defined?('@expected_value')
      @expected_value = begin
        @record.send("#{@attribute}=", value)
        @record.send(@attribute)
      end
    end

    if converted_value != @expected_value
      message = "Expected #{converter_class}"
      message += "\n  to convert #{value.inspect} to #{@expected_value.inspect}"
      message += ",\n  but actual output was #{converted_value.inspect}"
      @errors << message
    end

    @errors.empty?
  end

  chain :to do |expected_value|
    @expected_value = expected_value
  end

  chain :similar_to do |record|
    @record = record
  end

  chain :on do |attribute|
    @attribute = attribute
  end

  failure_message do
    @errors.join("\n")
  end
end
