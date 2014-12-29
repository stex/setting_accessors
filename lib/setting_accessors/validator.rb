class SettingAccessors::Validator < ActiveModel::Validator

  def validate(record)
    record.send(:validations).each do |key, requirement|
      send("validate_#{key}", record, requirement)
    end
  end

  private

  #
  # Validates that the setting's value is given
  # accepts :allow_blank and :allow_nil as options
  #
  def validate_presence(record, requirement)
    return true unless requirement

    if requirement.is_a?(Hash)
      if requirement['allow_blank'] && !record.value.nil? ||
           requirement['allow_nil'] && record.value.nil? ||
           record.value.present?
        true
      else
        add_error record, :blank
        false
      end
    else
      add_error_if record.value.nil? || record.value == '', record, :blank
    end
  end

  #
  # Validates numericality of the setting's value based on the options given
  # in settings.yml
  #
  def validate_numericality(record, options)
    #Test if the value is Numeric in any way (float or int)
    add_error_if(!parse_value_as_numeric(record.value), record, :not_a_number) && return

    #If the validation was set to check for integer values, do that as well
    add_error_if(options['only_integer'] && !parse_value_as_fixnum(record.value), record, :not_an_integer)
  end

  #
  # Validates whether the given value is a valid boolean
  #
  def validate_boolean(record, requirement)
    add_error_if(requirement && parse_value_as_boolean(record.value).nil?, record, :not_a_boolean)
  end

  #----------------------------------------------------------------
  #                        Helper Methods
  #----------------------------------------------------------------

  def add_error(record, validation, options = {})
    record.errors.add :value, validation, options
  end

  def add_error_if(cond, record, validation, options = {})
    add_error(record, validation, options) if cond
    cond
  end

  #
  # Borrowed from Rails' numericality validator
  # @return [Float, NilClass] the given String value as a float or nil
  #   if the value was not a valid Numeric
  #
  def parse_value_as_numeric(raw_value)
    Kernel.Float(raw_value) if raw_value !~ /\A0[xX]/
  rescue ArgumentError, TypeError
    nil
  end

  #
  # Borrowed from Rails' numericality validator
  #
  # @return [Fixnum, NilClass] the given String value as an int or nil
  #
  def parse_value_as_fixnum(raw_value)
    raw_value.to_i if raw_value.to_s =~ /\A[+-]?\d+\Z/
  end

  #
  # Tries to parse the given value as a boolean value
  #
  # @return [TrueClass, FalseClass, NilClass]
  #
  def parse_value_as_boolean(raw_value)
    case raw_value
      when TrueClass, FalseClass
        raw_value
      when String
        return true  if %w[true 1].include?(raw_value.downcase)
        return false if %w[false 0].include?(raw_value.downcase)
        nil
      else
        nil
    end
  end
end