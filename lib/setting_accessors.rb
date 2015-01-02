require 'setting_accessors/version'
require 'setting_accessors/accessor'
require 'setting_accessors/converter'
require 'setting_accessors/integration'
require 'setting_accessors/integration_validator'
require 'setting_accessors/setting_scaffold'
require 'setting_accessors/validator'

ActiveRecord::Base.class_eval do
  include SettingAccessors::Integration
end

module SettingAccessors
  def self.configuration(&proc)
    @@config ||= OpenStruct.new({
                                    :setting_class  => 'Setting',
                                    :class_settings => {}
                                })
    if block_given?
      yield @@config
      @@config.setting_class = (@@config.setting_class || 'Setting').to_s.classify
    else
      @@config
    end
  end

  #
  # Sets a class-specific setting
  # For global settings, this is done in config/settings.yml
  # Please do not call this method yourself, it is done automatically
  # by using setting_accessor in your model class
  #
  def self.set_class_setting(klass, setting_name, options)
    #If there are no options at all, we don't have to do anything.
    return if options.empty?

    #If the setting is already defined in config/settings.yml, raise an error
    if Setting.globally_defined?(setting_name) && options.any?
      raise ArgumentError.new("The setting #{setting_name} is already defined in config/settings.yml and may not be redefined in #{klass}.\nYou may therefore only use it in this class, but not redefine it.")
    else
      self.configuration.class_settings[klass.to_s] ||= {}
      self.configuration.class_settings[klass.to_s][setting_name.to_s] = options.deep_stringify_keys
    end
  end

  #
  # @return [Hash, NilClass] Information about a class specific setting or +nil+ if it wasn't set before
  #
  def self.get_class_setting(klass, setting_name)
    self.configuration.class_settings[klass.to_s].try(:[], setting_name.to_s)
  end

  #
  # @return [ActiveRecord::Base] (Setting)
  #   The class used to create new Settings in the system
  #
  def self.setting_class
    self.setting_class_name.constantize
  end

  #
  # @return [String] (Setting)
  #   The setting class' name
  #
  def self.setting_class_name
    @@config.setting_class.classify
  end
end
