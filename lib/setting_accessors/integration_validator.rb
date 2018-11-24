# frozen_string_literal: true

#
# This class handles model validations for assigned records, e.g.
# if the settings are accessed using the Accessor class in this module.
# Only the new temp values are validated using the setting config.
#
# The main work is still done in the Accessor class, so we don't have
# to access its instance variables here, this class acts as a wrapper
# for Rails' validation chain
#

class SettingAccessors::IntegrationValidator < ActiveModel::Validator
  def validate(record)
    record.settings.send(:validate!)
  end
end