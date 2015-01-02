require 'setting_accessors/version'
require 'setting_accessors/accessor'
require 'setting_accessors/converter'
require 'setting_accessors/integration'
require 'setting_accessors/integration_validator'
require 'setting_accessors/setting_scaffold'
require 'setting_accessors/validator'

module SettingAccessors
  def self.configuration(&proc)
    @@config ||= OpenStruct.new({
                                    :setting_class => 'Setting'
                                })
    if block_given?
      yield @@config
      @@config.setting_class = (@@config.setting_class || 'Setting').to_s.classify
    else
      @@config
    end
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
