# frozen_string_literal: true

module SettingAccessors::Integration
  def self.included(base)
    base.validates_with SettingAccessors::IntegrationValidator

    # After the main record was saved, we can save its settings.
    # This is necessary as the record might have been a new record
    # without an ID yet
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
    def setting_accessor(setting_name, options = {})
      SettingAccessors::Internal.set_class_setting(self, setting_name, options)

      setting_type = SettingAccessors::Internal.setting_value_type(setting_name, self).to_sym

      # Add the setting's name to the list of setting_accessors for this class
      SettingAccessors::Internal.add_setting_accessor_name(self, setting_name)

      # Getter
      define_method(setting_name) do
        settings.get_or_default(setting_name)
      end

      # Getter alias for boolean settings
      alias_method "#{setting_name}?", setting_name if setting_type == :boolean

      # Setter
      define_method("#{setting_name}=") do |new_value|
        settings[setting_name] = new_value
      end

      #NAME_was
      define_method("#{setting_name}_was") do
        settings.value_was(setting_name)
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

  #
  # Previously read setting values have to be refreshed if a record is reloaded.
  # Without this, #reload'ing a record would not update its setting values to the
  # latest database version if they were previously read.
  #
  # Example to demonstrate the problem with this override:
  #   user = User.create(:a_boolean => true)
  #   user_alias = User.find(user.id)
  #   user.a_boolean = !user_alias.a_boolean
  #   user.save
  #   user_alias.reload
  #   user_alias.a_boolean
  #   #=> true
  #
  def reload(*)
    super
    @settings_accessor = nil
    self
  end

  #
  # Adds changed settings to ActiveModel's list of changed attributes.
  # This is necessary for #changed? to work correctly without actually overriding
  # the method itself.
  #
  # TODO: Check if it makes more sense to hook into AR5's AttributeMutationTracker instead
  #
  # @return [Hash] All changed attributes
  #
  def changed_attributes
    super.merge(settings.changed_values)
  end

  def as_json(options = {})
    super.tap do |json|
      setting_names = SettingAccessors::Internal.setting_accessor_names(self.class)
      if options[:only]
        setting_names &= Array(options[:only]).map(&:to_s)
      elsif options[:except]
        setting_names -= Array(options[:except]).map(&:to_s)
      end

      setting_names.each do |setting_name|
        json[setting_name.to_s] = send(setting_name)
      end
    end
  end

  def settings
    @settings_accessor ||= SettingAccessors::Accessor.new(self)
  end
end
