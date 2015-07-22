class UserTest < ActiveSupport::TestCase
  context 'JSON serialization' do
    setup do
      @user = User.new(:a_string => 'test', :a_number => 42, :a_boolean => false)
    end

    should 'include the setting accessors' do
      puts @user.as_json
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
end
