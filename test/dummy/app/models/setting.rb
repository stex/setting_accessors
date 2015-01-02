#
# This model handles the management of system wide or record specific settings
#
# @attr [String] name
#   The setting's name
#
# @attr [Object] value
#   The setting's value. May be anything that can be serialized through YAML
#
# You can access global settings just like a normal class method,
# please have a look at #method_missing for more information.
#
# If not absolutely necessary, please **do not** create settings yourself
# through Setting.new, instead use #create_or_update instead.
#
# There are also some usage examples in the corresponding test.
#

class Setting < ActiveRecord::Base
  belongs_to :assignable, :polymorphic => true

  serialize :value

  include SettingAccessors::SettingScaffold

  #----------------------------------------------------------------
  #                        Validations
  #----------------------------------------------------------------

  validates :name,
            :uniqueness => {:scope => [:assignable_type, :assignable_id]},
            :presence   => true

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
      self.create_or_update(method_name[0..method_name.length-2], args.first, nil, true)
    else
      self.get(method_name, args.first)
    end
  end
end