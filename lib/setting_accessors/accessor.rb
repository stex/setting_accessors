#
# Helper class to make accessing record specific settings easier
# To use it, please include SettingAccessors::Integration into your model
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
    @temp_settings[key.to_sym] || Setting.get(key, @record)
  end

  #
  # Writes a setting's value
  #
  def []=(key, val)
    @temp_settings[key.to_sym] = val
  end

  #
  # Tries to find a setting for this record.
  # If none is found, will return the default setting value
  # specified in the setting config file.
  #
  def get_or_default(key)
    self[key] || Setting.get_or_default(key, @record)
  end

  #
  # Tries to find a setting for this record first.
  # If none is found, tries to find a global setting with the same name
  #
  def get_or_global(key)
    self[key] || Setting.get(key)
  end

  protected

  #
  # Validates the new setting values.
  # If there is an accessor for the setting, the errors will be
  # directly forwarded to it, otherwise to :base
  #
  # Please do not call this method directly, use the IntegrationValidator
  # class instead, e.g.
  #
  #   validates_with Stex::Settings::IntegrationValidator
  #
  def validate!
    @temp_settings.each do |key, value|
      validation_errors = Setting.validation_errors(key, value)
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
