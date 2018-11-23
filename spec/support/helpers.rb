# frozen_string_literal: true

module Helpers
  def setting_names(klass)
    SettingAccessors::Internal.setting_accessor_names(klass)
  end
end