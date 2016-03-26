#
# Helper class to make accessing record specific settings easier
#

class SettingAccessors::Accessor

  def initialize(record)
    @record        = record
    @temp_settings = {}
  end

  #
  # Gets a setting's value
  #
  def [](key)
    has_key?(key) ? @temp_settings[key.to_sym] : SettingAccessors.setting_class.get(key, @record)
  end

  #
  # Tries to fetch a setting value using the provided key and #[].
  # It will only return the +default+ value if there is
  #   - no temporary setting with the given key AND
  #   - no already persisted setting (see #[])
  #
  def fetch(key, default = nil)
    result = self[key]
    return default if result.nil? && !has_key?(key)
    result
  end

  #
  # Like #fetch, but it will store the default value as a temporary setting
  # if no actual setting value could be found. This is useful to further work
  # with default setting values.
  # The default value is cloned (using #dup to avoid copying object states) before
  # it is assigned. This will not work for singleton instances like true, false, etc.
  #
  def fetch_and_store(key, default = nil)
    result = self[key]
    if result.nil? && !has_key?(key)
      self[key] = default.duplicable? ? default.dup : default
    else
      result
    end
  end

  def has_key?(key)
    @temp_settings.has_key?(key.to_sym)
  end

  #
  # Writes a setting's value
  #
  def []=(key, val)
    set_value_before_type_cast(key, val)
    @temp_settings[key.to_sym] = SettingAccessors::Internal.converter(value_type(key)).convert(val)
  end

  #
  # Tries to find a setting for this record.
  # If none is found, will return the default setting value
  # specified in the setting config file.
  #
  def get_or_default(key)
    fetch_and_store(key, SettingAccessors.setting_class.get_or_default(key, @record))
  end

  #
  # Tries to find a setting for this record first.
  # If none is found, tries to find a global setting with the same name
  #
  def get_or_global(key)
    fetch_and_store(key, SettingAccessors.setting_class.get(key))
  end

  #
  # Tries to find a setting for this record first,
  # if none is found, it will return the given value instead.
  #
  def get_or_value(key, value)
    fetch_and_store(key, value)
  end

  def get_with_fallback(key, fallback = nil)
    return self[key] if fallback.nil?

    case fallback.to_s
      when 'default' then get_or_default(key)
      when 'global'  then get_or_global(key)
      else get_or_value(key, fallback)
    end
  end

  #
  # @return [String] the setting's value type in the +@record+'s context
  #
  def value_type(key)
    SettingAccessors::Internal.setting_value_type(key, @record)
  end

  #----------------------------------------------------------------
  #               ActiveRecord Helper Methods Emulation
  #----------------------------------------------------------------

  def value_was(key, fallback = nil)
    return SettingAccessors.setting_class.get(key, @record) if fallback.nil?

    case fallback.to_s
      when 'default' then SettingAccessors.setting_class.get_or_default(key, @record)
      when 'global'  then SettingAccessors.setting_class.get(key)
      else fallback
    end
  end

  def value_changed?(key)
    self[key] != value_was(key)
  end

  def value_before_type_cast(key)
    SettingAccessors::Internal.lookup_nested_hash(@values_before_type_casts, key.to_s) || self[key]
  end

  protected

  #
  # Keeps a record of the originally set value for a setting before it was
  # automatically converted.
  #
  def set_value_before_type_cast(key, value)
    @values_before_type_casts ||= {}
    @values_before_type_casts[key.to_s] = value
  end

  #
  # Validates the new setting values.
  # If there is an accessor for the setting, the errors will be
  # directly forwarded to it, otherwise to :base
  #
  # Please do not call this method directly, use the IntegrationValidator
  # class instead, e.g.
  #
  #   validates_with SettingAccessors::IntegrationValidator
  #
  def validate!
    @temp_settings.each do |key, value|
      validation_errors = SettingAccessors.setting_class.validation_errors(key, value, @record)
      validation_errors.each do |message|
        if @record.respond_to?("#{key}=")
          @record.errors.add(key, message)
        else
          @record.errors.add :base, :invalid_setting, :name => key, :message => message
        end
      end
    end
  end

  #
  # Saves the new setting values into the database
  # Please note that there is no check if the values changed their
  # in the meantime.
  #
  # Also, this method expects that the settings were validated
  # before using #validate! and will therefore not perform
  # validations itself.
  #
  def persist!
    @temp_settings.each do |key, value|
      Setting.create_or_update(key, value, @record)
    end
    flush!
  end

  def flush!
    @temp_settings = {}
  end
end
