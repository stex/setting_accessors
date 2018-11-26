# frozen_string_literal: true

module SettingAccessors
  module Integration
    def self.included(base)
      # After the main record was saved, we can save its settings.
      # This is necessary as the record might have been a new record
      # without an ID yet
      base.after_save do
        settings.send(:persist!)

        # From AR 5.1 on, #_update actually checks whether the changed "attributes" are actually
        # table columns or not. If no actual changed columns were found, the record is not changed and
        # only the after_* callbacks are executed.
        # This means that the settings are persisted, but the record's +updated_at+ column is not updated.
        #
        # This workaround triggers a #touch on the record in case no actual column change already
        # triggered a timestamp update.
        #
        # TODO: This might lead to #after_commit being triggered twice, once by #update_* and once by #touch
        touch if @_setting_accessors_touch_assignable
        @_setting_accessors_touch_assignable = false
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
      def setting_accessor(setting_name, **options)
        generator = AccessorGenerator.new(setting_name, **options)
        generator.assign_setting!(self)
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
      super.tap { @settings = nil }
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
      super.merge(settings.changed_settings)
    end

    #
    # Marks the record to be #touch'd after updating it in case no actual
    # attributes were involved and only settings were changed.
    # This is necessary for ActiveRecord >= 5.1 which will not perform the
    # timestamp updates if it thinks nothing actually changed.
    #
    if Gem.loaded_specs['activerecord'].version >= Gem::Version.create('5.1')
      def _update_record(*)
        super.tap do |affected_rows|
          # Workaround to trigger a #touch if necessary, see +after_save+ callback further up
          @_setting_accessors_touch_assignable = affected_rows.zero?
        end
      end
    end

    def as_json(options = {})
      super.tap do |json|
        SettingAccessors::Internal.json_setting_names(self.class, **options).each do |setting_name|
          json[setting_name.to_s] = send(setting_name)
        end
      end
    end

    def settings
      @settings ||= SettingAccessors::SettingSet.new(self)
    end
  end
end
