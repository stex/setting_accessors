require_relative '../../../test_helper'

class UserTest < ActiveSupport::TestCase
  context 'JSON serialization' do
    setup do
      @user = User.new(:a_string => 'test', :a_number => 42, :a_boolean => false)
    end

    should 'include the setting accessors' do
      SettingAccessors::Internal.setting_accessor_names(User).each do |setting_name|
        assert_includes @user.as_json.keys, setting_name
      end
    end

    should 'contain the correct values' do
      SettingAccessors::Internal.setting_accessor_names(User).each do |setting_name|
        assert_equal @user.as_json[setting_name.to_s], @user.send(setting_name)
      end
    end
  end

  context 'Boolean getter methods' do
    setup do
      @user = User.new(:a_string => 'test', :a_number => 42, :a_boolean => false)
    end

    should 'be created for boolean settings' do
      assert @user.respond_to?(:a_boolean?), '?-getter is not defined for boolean settings'
    end

    should 'return the same value as the original getter' do
      assert_equal @user.a_boolean, @user.a_boolean?
    end

    should 'not be created for non-boolean settings' do
      assert !@user.respond_to?(:a_number?)
      assert !@user.respond_to?(:a_string?)
    end
  end
end
