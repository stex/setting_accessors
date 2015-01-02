require_relative '../test_helper'

class InstallGeneratorTest < Rails::Generators::TestCase
  tests SettingAccessors::Generators::InstallGenerator
  destination File.expand_path('../dummy/tmp', File.dirname(__FILE__))
  setup    :prepare_destination

  test 'Assert all files are properly created' do
    run_generator
    assert_file 'config/settings.yml'
    assert_file 'config/initializers/setting_accessors.rb'
    assert_file 'app/models/setting.rb'
    assert_migration 'db/migrate/create_settings.rb'
  end
end