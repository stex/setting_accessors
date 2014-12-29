#
# This class contains methods to ensure that setting values
# are stored in the correct type. Validations are run before conversions,
# so there are no additional checks here.
#
# If the value cannot be parsed in the required type, +nil+ is assigned.
# Please make sure that you specify the correct validations in settings.yml
# to avoid this.
#

class SettingAccessors::Converter

  def initialize(record)
    @record = record
  end

  #
  # Converts the setting's value to the correct type
  #
  def convert(new_value)
    @value_before_type_cast = new_value
    return new_value if @record.type == 'polymorphic'

    parse_method = :"parse_#{@record.type}"

    if private_methods.include?(parse_method)
      send(parse_method, new_value)
    else
      raise ArgumentError.new("Invalid Setting type: #{@record.type}")
    end
  end

  def value_before_type_cast
    @value_before_type_cast
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