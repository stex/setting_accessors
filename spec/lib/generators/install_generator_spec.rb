# frozen_string_literal: true

require 'generator_spec'
require 'generators/setting_accessors/install_generator'

describe SettingAccessors::Generators::InstallGenerator, type: :generator do
  destination File.expand_path('../../../tmp', File.dirname(__FILE__))

  before(:all) do
    prepare_destination
    run_generator
  end

  it 'creates the initializer' do
    assert_file 'config/initializers/setting_accessors.rb'
  end

  it 'creates the model' do
    assert_file 'app/models/setting.rb'
  end

  it 'creates the migration' do
    assert_migration 'db/migrate/create_settings.rb'
  end
end
