# frozen_string_literal: true

module SettingModel
  def self.included(base)
    base.with_model 'Setting' do
      table do |t|
        t.belongs_to :assignable, polymorphic: true, index: false
        t.string :name
        t.text :value
        t.timestamps null: false
      end

      model do
        if Gem.loaded_specs['activerecord'].version >= Gem::Version.create('5.0')
          belongs_to :assignable, polymorphic: true, optional: true
        else
          belongs_to :assignable, polymorphic: true
        end

        serialize :value
        include SettingAccessors::SettingScaffold
      end
    end
  end
end
