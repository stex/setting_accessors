module SettingAccessors::Integration
  def self.included(base)
    base.validates_with SettingAccessors::IntegrationValidator

    #After the main record was saved, we can save its settings.
    #This is necessary as the record might have been a new record
    #without an ID yet
    base.after_save do
      settings.send(:persist!)
    end

    base.extend ClassMethods
  end

  module ClassMethods

    #
    # Generates a new accessor (=getter and setter) for the given setting
    #
    # @param [String, Symbol] setting_name
    #   The setting's name
    #
    # @param [Hash] options
    #   Options to customize the behaviour of the generated accessor
    #
    # @option options [Symbol, Object] :fallback (nil)
    #   If set to +:default+, the getter will return the setting's default
    #   value if no own value was specified for this record
    #
    #   If set to +:global+, the getter will try to find a global
    #   setting if no record specific setting was found
    #
    #   If set to another value, this value is used by default
    #
    #   If not set at all or to +nil+, the getter will only search for a record specific
    #   setting and return +nil+ if none was specified previously.
    #
    def setting_accessor(setting_name, options = {})
      fallback = options.delete(:fallback)

      SettingAccessors::Internal.set_class_setting(self, setting_name, options)

      #Create a virtual column in the models column hash.
      #This is currently not absolutely necessary, but will become important once
      #Time etc. are supported. Otherwise, Rails won't be able to e.g. automatically
      #create multi-param fields in forms.
      self.columns_hash[setting_name.to_s] = OpenStruct.new(type: SettingAccessors::Internal.setting_value_type(setting_name, self.new).to_sym)

      #Getter
      define_method(setting_name) do
        settings.get_with_fallback(setting_name, fallback)
      end

      # Setter
      define_method("#{setting_name}=") do |new_value|
        settings[setting_name] = new_value
      end

      #NAME_was
      define_method("#{setting_name}_was") do
        settings.value_was(setting_name, fallback)
      end

      #NAME_before_type_cast
      define_method("#{setting_name}_before_type_cast") do
        settings.value_before_type_cast(setting_name)
      end

      #NAME_changed?
      define_method("#{setting_name}_changed?") do
        settings.value_changed?(setting_name)
      end
    end
  end

  def settings
    @settings_accessor ||= SettingAccessors::Accessor.new(self)
  end
end