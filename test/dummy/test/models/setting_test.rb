require 'test_helper'

class SettingTest < ActiveSupport::TestCase
  should validate_presence_of :name
  should validate_uniqueness_of(:name).scoped_to([:assignable_type, :assignable_id])

  context 'Global Setting Accessors (method missing)' do

    should 'ignore a setting function if more than 1 argument is given' do
      assert_raises(NoMethodError) { Setting.my_setting(1, 2, 3) }
    end

    should 'return nil for a non-existing setting' do
      assert_nil Setting.gotta_catch_em_all
    end

    should 'create a new setting if necessary' do
      assert Setting.count.zero?
      assert Setting.gotta_catch_em_all = 'Pokemon!'
      assert Setting.count == 1
    end

    should "return the setting's value for an existing setting" do
      assert Setting.gotta_catch_em_all = 'Pokemon!'
      assert_equal Setting.gotta_catch_em_all, 'Pokemon!'
    end

    should 'update an existing setting instead of creating a new one' do
      assert Setting.count.zero?
      assert Setting.gotta_catch_em_all = 'Pokemon!'
      assert Setting.gotta_catch_em_all = 'Pokemon!'
      assert Setting.count == 1
    end

    should 'return assignable specific settings if an assignable is given' do
      ash         = FactoryGirl.create(:user, :first_name => 'Ash', :last_name => 'Ketchum')
      gary        = FactoryGirl.create(:user, :first_name => 'Gary', :last_name => 'Oak')
      team_rocket = FactoryGirl.create(:user, :first_name => 'Jessie', :last_name => 'James')

      assert Setting.create_or_update(:pokedex_count, 151, ash)
      assert Setting.create_or_update(:pokedex_count, 1, gary)

      assert_nil Setting.pokedex_count

      assert_equal Setting.pokedex_count(ash), 151
      assert_equal Setting.pokedex_count(gary), 1

      #They don't want to be on file.
      assert_nil Setting.pokedex_count(team_rocket)
    end
  end

  context 'The create_or_update function' do
    setup do
      @ash  = FactoryGirl.create(:user, :first_name => 'Ash', :last_name => 'Ketchum')
    end

    should 'create a new assigned setting if it did not exist before' do
      assert Setting.count.zero?
      Setting.create_or_update(:pokedex_count, 151, @ash)
      assert Setting.count == 1
    end

    should 'update an assigned setting if it already exists' do
      Setting.create_or_update(:pokedex_count, 150, @ash)
      assert Setting.count == 1
      Setting.create_or_update(:pokedex_count, 151, @ash)
      assert Setting.count == 1
      assert_equal Setting.pokedex_count(@ash), 151
    end

    should 'return a setting object by default' do
      assert_instance_of Setting, Setting.create_or_update(:pokedex_count, 151, @ash)
    end

    should 'return just the value if wished' do
      assert_equal Setting.create_or_update(:pokedex_count, 151, @ash, true), 151
    end
  end
end
