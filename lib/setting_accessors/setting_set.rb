# frozen_string_literal: true

#
# Helper class to make accessing record specific settings easier
#
module SettingAccessors
  class SettingSet
    include ::SettingAccessors::Helpers

    attr_reader :record

    def initialize(record)
      @record = record
      @temp_settings = {}
    end

    #
    # Tries to retrieve the given setting's value from the temp settings
    # (already read/written values in this instance). If the setting hasn't been
    # used before, its value is retrieved from the database.
    #
    # If a setting hasn't been read by this record (instance) before, its value
    # is stored in the local read set.
    #
    def get(key)
      return @temp_settings[key.to_sym] if key?(key)

      @temp_settings[key.to_sym] = current_database_value!(key)
    rescue SettingNotFoundError
      nil
    end

    alias [] get

    def key?(key)
      @temp_settings.key?(key.to_sym)
    end

    #
    # Writes a setting's value
    #
    def set(key, val)
      track_old_value(key)
      set_value_before_type_cast(key, val)
      @temp_settings[key.to_sym] = SettingAccessors::Internal.converter(value_type(key)).new(val).convert
    end

    alias []= set

    #
    # Tries to find a setting for this record.
    # If none is found, will return the default setting value
    # specified in the setting accessor call
    #
    # @param [Boolean] store_default
    #   If set to +true+, the setting's default value is written to the temporary settings
    #   for faster access. Otherwise, a database lookup is performed every time.
    #
    def get_or_default(key, store_default: true)
      result = get(key)
      return result if key?(key) # If no key is found here, we didn't have a setting in the database

      try_dup(default_value(key)).tap do |value|
        set(key, value) if store_default
      end
    end

    #
    # @return [String] the setting's value type in the +record+'s context
    #
    def value_type(key)
      SettingAccessors::Internal.setting_value_type(key, record)
    end

    #----------------------------------------------------------------
    #               ActiveRecord Helper Methods Emulation
    #----------------------------------------------------------------

    #
    # @return [Object] the value the given setting had after it was last persisted
    #
    def value_was(key)
      lookup_nested_hash(@old_values, key.to_s)
    rescue NestedHashKeyNotFoundError
      current_database_value(key)
    end

    #
    # @return [Boolean] +true+ if the value for the given setting differs from the database or default value
    #
    def value_changed?(key)
      get(key) != value_was(key)
    end

    #
    # @return [Object] The raw value passed to this setting before it was casted to the correct type
    #
    def value_before_type_cast(key)
      lookup_nested_hash(@values_before_type_casts, key.to_s)
    rescue NestedHashKeyNotFoundError
      get(key)
    end

    #
    # @return [Hash] the settings which were actually changed since the last persist!
    #
    def changed_settings
      @temp_settings.select { |k, _| value_changed?(k) }
    end

    protected

    #
    # @return [Object] the current setting value from the database or +nil+ if the setting does not exist yet.
    #
    def current_database_value(key)
      SettingAccessors.setting_class.get(key, record)
    end

    #
    # Like #current_database_value, but will raise a SettingNotFound exception
    # if there is no current database value
    #
    def current_database_value!(key)
      SettingAccessors.setting_class.get!(key, record)
    end

    #
    # @return [Object] the default value for the given setting
    #
    def default_value(key)
      SettingAccessors.setting_class.get_default_value(key, record)
    end

    #
    # Keeps a record of the originally set value for a setting before it was
    # automatically converted.
    #
    def set_value_before_type_cast(key, value)
      @values_before_type_casts ||= {}
      @values_before_type_casts[key.to_s] = value
    end

    #
    # Keeps a local copy of a setting's value before it was overridden.
    # Once the setting is persisted, this value is cleared.
    #
    def track_old_value(key)
      @old_values ||= {}

      unless @old_values.key?(key.to_s)
        @old_values[key.to_s] = begin
                                  current_database_value!(key)
                                rescue SettingNotFoundError
                                  default_value(key)
                                end
      end
    end

    #
    # @return [Object] the duplicated value if it is in fact duplicable. The actual value otherwise
    #
    def try_dup(value)
      value.duplicable? ? value.dup : value
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
      changed_settings.each do |key, value|
        Setting.set(key, value, assignable: record)
      end
      flush!
    end

    def flush!
      @temp_settings = {}
      @values_before_type_casts = {}
      @old_values = {}
    end
  end
end
