# frozen_string_literal: true

module SettingModel
  def self.included(base)
    base.with_model 'Setting' do
      table do |t|
        t.belongs_to :assignable, polymorphic: true, index: false
        t.string :name
        t.text :value
        t.timestamps
      end

      model do
        belongs_to :assignable, :polymorphic => true
        serialize :value
        include SettingAccessors::SettingScaffold

        #----------------------------------------------------------------
        #                        Validations
        #----------------------------------------------------------------

        validates :name,
                  uniqueness: {scope: [:assignable_type, :assignable_id]},
                  presence: true

        validates_with SettingAccessors::Validator
      end
    end
  end
end