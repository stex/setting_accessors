# frozen_string_literal: true

#
# This class handles creating everything necessary for a new setting_accessor
# and the actual method assignment in the calling class.
#
module SettingAccessors
  class AccessorGenerator
    attr_reader :setting_name
    attr_reader :options

    def initialize(setting_name, **options)
      @setting_name = setting_name
      @options = options
    end

    def assign_setting!(klass)
      SettingAccessors::Internal.set_class_setting(klass, setting_name, options)
      define_getters(klass)
      define_setter(klass)
      define_active_record_helpers(klass)
    end

    private

    def define_getters(klass, outer_setting_name = setting_name)
      klass.define_method(setting_name) do
        settings.get_or_default(outer_setting_name)
      end

      # Getter alias for boolean settings
      setting_type = SettingAccessors::Internal.setting_value_type(setting_name, klass).to_sym
      klass.alias_method "#{outer_setting_name}?", outer_setting_name if setting_type == :boolean
    end

    def define_setter(klass, outer_setting_name = setting_name)
      klass.define_method("#{setting_name}=") do |new_value|
        settings[outer_setting_name] = new_value
      end
    end

    def define_active_record_helpers(klass, outer_setting_name = setting_name)
      # NAME_was
      klass.define_method("#{setting_name}_was") do
        settings.value_was(outer_setting_name)
      end

      # NAME_before_type_cast
      klass.define_method("#{setting_name}_before_type_cast") do
        settings.value_before_type_cast(outer_setting_name)
      end

      # NAME_changed?
      klass.define_method("#{setting_name}_changed?") do
        settings.value_changed?(outer_setting_name)
      end
    end
  end
end
