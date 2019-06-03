# frozen_string_literal: true

module Helpers
  def self.min_ar_version(version)
    Gem.loaded_specs['activerecord'].version >= Gem::Version.create(version)
  end

  def setting_names(klass)
    SettingAccessors::Internal.setting_accessor_names(klass)
  end
end
