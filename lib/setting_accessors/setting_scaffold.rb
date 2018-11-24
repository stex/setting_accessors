#
# Helper methods for the chosen setting model
# They are in this module to leave the end developer some room for
# his own methods in the setting model for his own methods.
#

module SettingAccessors::SettingScaffold

  def self.included(base)
    base.extend ClassMethods
    base.validates_with SettingAccessors::Validator
    base.serialize :value

    base.validates :name,
                   :uniqueness => {:scope => [:assignable_type, :assignable_id]},
                   :presence   => true
  end

  module ClassMethods
    #
    # Searches for a setting in the database and returns its value
    #
    # @param [String, Symbol] name
    #   The setting's name
    #
    # @param [ActiveRecord::Base] assignable
    #   If given, the setting searched has to be assigned to the given record
    #   If not given, a global setting is searched
    #
    # @return [Object, NilClass]
    #   If a setting is found, **its value** is returned.
    #   If not, +nil+ is returned.
    #
    def get(name, assignable = nil)
      self.setting_record(name, assignable).try(:value)
    end

    alias_method :[], :get

    #
    # Tries to look the setting up using #get, if no existing setting is found,
    # the setting's default value is returned.
    #
    # This only works for class-wise settings, meaning that an assignable has to be present.
    #
    def get_or_default(name, assignable)
      if (val = get(name, assignable)).nil?
        new(name: name, assignable: assignable).default_value
      else
        val
      end
    end

    #
    # Creates or updates the setting with the given name
    #
    # @param [String, Symbol] name
    #   The setting's name
    #
    # @param [Object] value
    #   The new setting value
    #
    # @param [ActiveRecord::Base] assignable
    #   The optional record this setting belongs to. If not
    #   given, the setting is global.
    #
    # @param [Boolean] return_value
    #   If set to +true+, only the setting's value is returned
    #
    # @return [Object] The newly set value
    #
    # @toto: Bless the rains down in Africa!
    #
    def set(name, value, assignable: nil)
      (setting_record(name, assignable) || new(name: name, assignable: assignable)).tap do |setting|
        setting.set_value(value)
        setting.save
      end.value
    end

    alias_method :[]=, :set

    #
    # @return [Object] the default value for the given setting
    #
    def get_default_value(name, assignable = nil)
      self.new(:name => name, :assignable => assignable).default_value
    end

    #
    # Looks up a setting record for the given name and assignable
    # Unlike the other methods here, this one actually returns a Setting object
    # instead of its value.
    #
    # @return [Setting, NilClass] The found setting or nil if not existing
    #
    def setting_record(name, assignable = nil)
      self.find_by(:name => name.to_s, :assignable => assignable)
    end

    #
    # Tests, if the given value would be valid for the given
    # setting name. This is done in this class method due to
    # the process of setting creation through assigned records
    # which does not allow going the "normal" way of testing whether
    # a setting was saved correctly or not.
    #
    # @return [Array<String>] The validation errors for the setting's value
    #
    def validation_errors(name, value, assignable = nil)
      s = self.new(:name => name, :value => value, :assignable => assignable)
      s.valid?
      s.errors[:value] || []
    end

    #
    # Makes accessing settings a little easier.
    # Examples:
    #
    #   #Loading **the value** of a global setting named "my_setting"
    #   Setting.my_setting
    #
    #   #Setting **the value** of a global setting named "my_setting"
    #   Setting.my_setting = [1,2,3,4,5]
    #
    #   #Loading **the value** of an assigned setting named "cool_setting"
    #   #+some_cool_user+ is here an instance of ActiveRecord::Base
    #   Setting.cool_setting(some_cool_user)
    #
    def method_missing(method, *args, &block)
      method_name = method.to_s

      if method_name.last == '='
        set(method_name[0..-2], args.first)
      else
        return super(method, *args, &block) if args.size > 1
        get(method_name, args.first)
      end
    end
  end

  #
  # @return [String] the localized setting name
  #   they are stored in config/locales/settings.LOCALE.yml
  #
  def localized_name
    i18n_lookup(:name)
  end

  #
  # @return [String] the localized setting description
  #   see #localized_name
  #
  def localized_description
    i18n_lookup(:description)
  end

  #
  # Performs an I18n lookup in the settings locale.
  # Class based settings are store in 'settings.CLASS.NAME', globally defined settings
  # in 'settings.global.NAME'
  #
  def i18n_lookup(key, options = {})
    options[:scope] = [:settings, :global, self.name]
    options[:scope] = [:settings, self.assignable.class.to_s.underscore, self.name] unless SettingAccessors::Internal.globally_defined_setting?(self.name)
    I18n.t(key, options)
  end

  #
  # @return [Object] the default value for the current setting
  #
  def default_value
    data['default'].freeze
  end

  #
  # @return [String] the setting's type as specified in settings.yml
  #   If the setting wasn't specified, a polymorphic type is assumed
  #
  def value_type
    data['type'] || 'polymorphic'
  end

  #
  # @return [Object] the setting's value before it was type casted using the defined rule in settings.yml
  #   See #value_before_type_cast for ActiveRecord attributes
  #
  # We can't use the name #value_before_type_cast here as it would
  # shadow ActiveRecord's default one - which might still be needed.
  #
  def original_value
    @original_value || self.value
  end

  #
  # Sets the setting's value to the given one
  # Performs automatic type casts
  #
  def set_value(new_value)
    @original_value = new_value
    self.value      = converter.convert(new_value)
  end

  private

  def converter
    @converter ||= SettingAccessors::Internal.converter(value_type)
  end

  def value_required?
    !!validations['required']
  end

  #
  # Accessor to the validations part of the setting's data
  #
  def validations
    data['validates'] || {}
  end

  #
  # @see {SettingAccessors::Internal#setting_data} for more information
  #
  def data
    SettingAccessors::Internal.setting_data(name, assignable)
  end

end
