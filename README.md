SettingAccessors
================

[![Gem Version](https://badge.fury.io/rb/setting_accessors.svg)](http://badge.fury.io/rb/setting_accessors)
[![Build Status](https://travis-ci.org/Stex/setting_accessors.svg?branch=master)](https://travis-ci.org/Stex/setting_accessors)
[![Maintainability](https://api.codeclimate.com/v1/badges/78becd1d005aab2d1409/maintainability)](https://codeclimate.com/github/Stex/setting_accessors/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/a99a88d28ad37a79dbf6/test_coverage)](https://codeclimate.com/github/Stex/setting_accessors/test_coverage)

Sometimes it's handy to keep track of various settings or attributes in ActiveRecord instances and persist them through various requests (and sessions). An example would be to store a items-per-page value for multiple tables in the application per user or probably also set default sorting directions.

The only problem is, that it would be necessary to either keep hundreds of columns in the corresponding table or create a serialized attribute which would grow over time and generally be hard to manage.

This gem consists of a global key-value-store, allowing to use both global and record bound settings
and ActiveRecord integration to add virtual columns to models without having to change the database layout.

Version Information / Backwards Compatibility
---------------------------------------------

The current version (1.x) is only compatible with Ruby >= 2.3 and Rails >= 4.2.  
Versions 0.x support older versions of both Ruby and Rails. 

Version 0.x also supported validations and type conversions for globally defined settings
(`Setting.my_setting = 5`).  
This was removed in this version, so developers should make sure that the assigned
value has the correct type themselves.

Validations for class-wise defined `setting_accessor`s can still be realized using 
ActiveModel's integrated validators as described below.

Installation
------------

Add this line to your application's Gemfile:

```ruby
gem 'setting_accessors'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install setting_accessors
```

The gem requires a few additional files to work properly:

-	A migration to create the settings table
-	A setting model
-	An initializer

All of them can be generated using the provided generator:

```
$ rails g setting_accessors:install MODEL_NAME
```

If no model name is given, the default one (`Setting`) is used.

Usage as a global key-value-store 
-----

In the following, the model name will be assumed as `Setting`, 
though you may choose its name freely using the provided generator (see above).

Settings can either be global or assigned to an instance of ActiveRecord::Base. 
They consist of a name which is unique either in the global scope or within the instance 
and a value which can be everything that's serializable through YAML.

The easiest way to use the settings model is as a global key-value-store without validations and typecasting.

Values can be easily set and retrieved by using their names as class method names on `Setting` itself:

```ruby
Setting.the_meaning_of_life = 42
Setting.the_meaning_of_life
#=> 42
```

If the name contains characters which are not allowed due to ruby naming rules, 
you can also use the methods`Setting[KEY]` resp. `Setting.get(KEY)` to get a setting's value 
and `Setting[KEY] = VALUE` resp.`Setting.set(KEY, VALUE)`.

Therefore, the following getter methods are equivalent:

```ruby
Setting.meaning_of_life
Setting[:meaning_of_life]
Setting.get(:meaning_of_life)
```

For the corresponding setters:

```ruby
Setting.meaning_of_life   = 42
Setting[:meaning_of_life] = 42
Setting.set(:meaning_of_life, 42)
```

This makes it also possible to use Ruby's or-equals operator:

```ruby
Setting.meaning_of_life ||= 42
Setting[:meaning_of_life] ||= 42
``` 

### Assigned Records

Global settings can also be assigned to an instance of `ActiveRecord::Base` without 
having to define them in the model first.

An example would be to save "items per page" values for various views: 
Let's say we have an events view and want to save how many rows/items each user would like to display.

As there might be many views requiring this functionality, it wouldn't make
sense to define global settings for each of them. Instead, we would use anonymous
settings with a generated key based on the current view:

```ruby
def items_per_page
  key           = [controller_path, action_name].join('_')
  default_value = 30
  Setting.get(key, current_user) || default_value
end

def set_items_per_page
  key = [controller_path, action_name].join('_')
  Setting.set(key, params[:per_page], assignable: current_user) || default_value
end
```

The following calls are equivalent:

```ruby
Setting[:meaning_of_life, current_universe] = 42
Setting.set(:meaning_of_life, 42, assignable: current_universe)
```

`[]=` is not an exact alias of `set` here to still support `or-else`:

```ruby
Setting[:meaning_of_life, current_universe] ||= 42
```

ActiveRecord Integration
------------------------

The gem adds the method `setting_accessor` to each class which inherits from `ActiveRecord::Base`.

It basically generates an `attribute_accessor` with the given name, but also makes sure that
the value is persisted when the actual record is saved. It also provides the standard attribute helper
methods ActiveRecord adds for each database column (`ATTRIBUTE_changed?`, `ATTRIBUTE_was`, ...).

It aims to simulate an actual database column.

```ruby
class MyModel < ActiveRecord::Base
  setting_accessor :my_setting, type: :boolean, default: false
end
```

### Options

```ruby
type: :string | :integer | :boolean | :polymorphic
```

`:type` defines the setting's data type. If no type is given, `:polymorhpic` is used automatically.

For every other type, the setting's value is automatically converted accordingly
upon setting it, mimicking ActiveRecord's type casting based on database types.
Please note that `:polymorphic` values are saved as is, meaning that you can
store everything that's serializable.

```ruby
default: Object
```

`:default` sets the setting's default value that is returned as long no actual setting exists for
that name/assignable.

### Validations

Attributes created by `setting_accessor` can simply be used with `ActiveModel::Validations` the same way
as other attributes: 

```ruby
setting_accessor :my_string, type: :string
setting_accessor :my_number, type: :integer

validates :my_string, presence: true
validates :my_number, numericality: {only_integer: true}
```

Contributors
------------

<a href="https://github.com/stex/setting_accessors/graphs/contributors">
  <img src="https://contributors-img.firebaseapp.com/image?repo=stex/setting_accessors" />
</a>

Made with [contributors-img](https://contributors-img.firebaseapp.com).

Contributing
------------

1.	Fork it ( https://github.com/stex/setting_accessors/fork )
2.	Create your feature branch (`git checkout -b my-new-feature`\)
3.	Commit your changes (`git commit -am 'Add some feature'`\)
4.	Push to the branch (`git push origin my-new-feature`\)
5.	Create a new Pull Request
