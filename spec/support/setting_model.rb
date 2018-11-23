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

        #
        # Makes accessing settings a little easier.
        # Examples:
        #
        #   #Loading **the value** of a global setting named "my_setting"
        #   Setting.my_setting
        #
        #   #Setting **the value** of a global setting named "my_setting"
        #   Setting.my_setting = [1,2,3,4,5]
        #
        #   #Loading **the value** of an assigned setting named "cool_setting"
        #   #+some_cool_user+ is here an instance of ActiveRecord::Base
        #   Setting.cool_setting(some_cool_user)
        #
        def self.method_missing(method, *args)
          super(method, *args) if args.size > 1
          method_name = method.to_s
          if method_name.last == '='
            self.create_or_update(method_name[0..method_name.length - 2], args.first, nil, true)
          else
            self.get(method_name, args.first)
          end
        end
      end
    end
  end
end