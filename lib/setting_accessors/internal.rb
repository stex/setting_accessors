# frozen_string_literal: true

#
# This module contains class methods used internally.
#
module SettingAccessors
  module Internal
    extend Helpers

    def self.class_settings
      @@class_settings ||= {}
    end

    #
    # Sets a class-specific setting
    # For global settings, this is done in config/settings.yml
    # Please do not call this method yourself, it is done automatically
    # by using setting_accessor in your model class
    #
    def self.set_class_setting(klass, setting_name, options = {})
      # If there are no options given, the setting *has* to be defined globally.
      if options.empty?
        raise ArgumentError, "The setting '#{setting_name}' in model '#{klass.to_s}' is lacking options."
      # If the setting is defined on class base, we have to store its options
      else
        ensure_nested_hash!(class_settings, klass.to_s)
        class_settings[klass.to_s][setting_name.to_s] = options.deep_stringify_keys
      end
    end

    #
    # @return [Hash] configuration data regarding this setting
    #
    #   - If it's a globally defined setting, the value is taken from config/settings.yml
    #   - If it's a setting defined in a setting_accessor call, the information is taken from this call
    #   - Otherwise, an empty hash is returned
    #
    def self.setting_data(setting_name, assignable_class = nil)
      # As a convenience function (and to keep the existing code working),
      # it is possible to provide a class or an instance of said class
      assignable_class &&= assignable_class.class unless assignable_class.is_a?(Class)
      (assignable_class && get_class_setting(assignable_class, setting_name)) || {}
    end

    #
    # @return [String] the given setting's value type
    #
    def self.setting_value_type(*args)
      setting_data(*args)['type'] || 'polymorphic'
    end

    #
    # @return [SettingAccessors::Converter] A value converter for the given type
    #
    def self.converter(value_type)
      Converters.const_get("#{value_type.to_s.camelize}Converter")
    end

    #
    # @return [Hash, nil] Information about a class specific setting or +nil+ if it wasn't set before
    #
    def self.get_class_setting(klass, setting_name)
      lookup_nested_hash(class_settings, klass.to_s, setting_name.to_s)
    rescue ::SettingAccessors::Helpers::NestedHashKeyNotFoundException
      nil
    end

    #
    # Adds the given setting name to the list of used setting accessors
    # in the given class.
    # This is mainly to keep track of all accessors defined in the different classes
    #
    def self.add_setting_accessor_name(klass, setting_name)
      @@setting_accessor_names ||= {}
      @@setting_accessor_names[klass.to_s] ||= []
      @@setting_accessor_names[klass.to_s] << setting_name.to_s
    end

    #
    # @return [Array<String>] all setting accessor names defined in the given +class+
    #
    def self.setting_accessor_names(klass)
      @@setting_accessor_names ||= {}
      lookup_nested_hash(@@setting_accessor_names, klass.to_s) || []
    end

  end
end
