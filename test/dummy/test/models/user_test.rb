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

  context 'Polymorphic class-wise settings' do
    setup do
      @user = User.create
    end

    should 'be updated in database if their whole value changes' do
      @user.polymorphic_setting = {:a => :b}
      assert @user.save
      assert_equal User.last, @user
      assert_equal User.last.polymorphic_setting, {:a => :b}
    end

    should 'be updated in database if a property of their value changes' do
      @user.polymorphic_setting[:new_key] = 'new_value'
      assert @user.save
      assert_equal User.last, @user
      assert_equal User.last.polymorphic_setting, {:new_key => 'new_value'}
    end

    should 'not update other assignable settings' do
      @user2 = User.create
      @user2.polymorphic_setting = {:foo => :bar}
      assert @user2.save
      assert_equal User.first.polymorphic_setting, {}
    end
  end
end
