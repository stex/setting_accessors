module SettingAccessors::Integration
  def self.included(base)
    base.validates_with SettingAccessors::IntegrationValidator

    #After the main record was saved, we can save its settings.
    #This is necessary as the record might have been a new record
    #without an ID yet
    after_save do
      settings.send(:persist!)
    end

    extend ClassMethods
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
    # @option options [Symbol] :fallback (nil)
    #   If set to +:default+, the getter will return the setting's default
    #   value if no own value was specified for this record
    #
    #   If set to +:global+, the getter will try to find a global
    #   setting if no record specific setting was found
    #
    #   Otherwise, the getter will only search for a record specific
    #   setting and return +nil+ if none was specified previously.
    #
    def setting_accessor(setting_name, options = {})
      define_method(setting_name) do
        if options[:fallback].to_s == 'default'
          settings.get_or_default(setting_name)
        elsif options[:fallback].to_s == 'global'
          settings.get_or_global(setting_name)
        else
          settings[setting_name]
        end
      end

      define_method("#{setting_name}=") do |new_value|
        settings[setting_name] = new_value
      end
    end
  end

  def settings
    @settings_accessor ||= SettingAccessors::Accessor.new(self)
  end
end