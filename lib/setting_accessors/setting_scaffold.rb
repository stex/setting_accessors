# frozen_string_literal: true

#
# Helper methods for the chosen setting model
# They are in this module to leave the end developer some room for
# his own methods in the setting model for his own methods.
#

module SettingAccessors
  module SettingScaffold

    def self.included(base)
      base.extend ClassMethods
      base.serialize :value

      base.validates :name,
                     uniqueness: {scope: [:assignable_type, :assignable_id]},
                     presence: true
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
        setting_record(name, assignable).try(:value)
      end

      alias [] get

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
          setting.raw_value = value
          setting.save
        end.value
      end

      #
      # An alias for #set with a slightly different API.
      # This allows the following usage:
      #    Setting['my_setting', my_assignable] ||= new_value
      #
      def []=(name, *args)
        assignable = args.size > 1 ? args.first : nil
        set(name, args.last, assignable: assignable)
      end

      #
      # @return [Object] the default value for the given setting
      #
      def get_default_value(name, assignable = nil)
        new(name: name, assignable: assignable).default_value
      end

      #
      # Looks up a setting record for the given name and assignable
      # Unlike the other methods here, this one actually returns a Setting object
      # instead of its value.
      #
      # @return [Setting, NilClass] The found setting or nil if not existing
      #
      def setting_record(name, assignable = nil)
        find_by(name: name.to_s, assignable: assignable)
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
          return set(method_name[0..-2], args.first)
        elsif args.size <= 1
          return get(method_name, args.first)
        end

        super
      end
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
    def raw_value
      @raw_value || value
    end

    #
    # Sets the new setting value by converting the raw value automatically.
    #
    def raw_value=(new_value)
      @raw_value = new_value
      self.value = converter.new(new_value).convert
    end

    private

    def converter
      @converter ||= SettingAccessors::Internal.converter(value_type)
    end

    #
    # @see {SettingAccessors::Internal#setting_data} for more information
    #
    def data
      SettingAccessors::Internal.setting_data(name, assignable)
    end
  end
end
