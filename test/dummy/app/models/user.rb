class User < ActiveRecord::Base

  setting_accessor :locale, :type => :string, :validations => {:presence => true}

  setting_accessor :a_string, :fallback => :default

  setting_accessor :a_number, :fallback => :global

  setting_accessor :a_boolean, :fallback => false

  setting_accessor :class_wise_truthy_boolean, :type => :boolean, :default => true, :fallback => :default

  setting_accessor :class_wise_with_value_fallback, :type => :string, :fallback => 'Oiski Poiski!'

  setting_accessor :class_wise_with_default_fallback, :type => :string, :fallback => :default, :default => 'Kapitanski'

end
