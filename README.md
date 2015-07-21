SettingAccessors
================

[![Gem Version](https://badge.fury.io/rb/setting_accessors.svg)](http://badge.fury.io/rb/setting_accessors)
[![Build Status](https://travis-ci.org/Stex/setting_accessors.svg?branch=master)](https://travis-ci.org/Stex/setting_accessors)

Sometimes it's handy to keep track of various settings or attributes in ActiveRecord instances and persist them through various requests (and sessions). An example would be to store a items-per-page value for multiple tables in the application per user or probably also set default sorting directions.

The only problem is, that it would be necessary to either keep hundreds of columns in the corresponding table or create a serialized attribute which would grow over time and generally be hard to manage.

This gem consists of a global key-value-store, allowing to use both global and record bound settings
and ActiveRecord integration to add virtual columns to models without having to change the database layout.

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
-	A settings config file (config/settings.yml)

All of them can be generated using the provided generator:

```
$ rails g setting_accessors:install MODEL_NAME
```

If no model name is given, the default one (`Setting`) is used.

Usage as a global key-value-store (globally defined and anonymous settings)
-----

In the following, the model name will be assumed as `Setting`, though you may choose its name freely using the provided generator (see above).

Settings can either be global or assigned to an instance of ActiveRecord::Base. They consist of a name which is unique either in the global scope or within the instance and a value which can be everything that's serializable through YAML.

The easiest way to use the settings model is as a global key-value-store without validations and typecasting.

Values can be easily set and retrieved by using their names as class method names on `Setting` itself:

```ruby
Setting.the_meaning_of_life = 42
Setting.the_meaning_of_life
#=> 42
```

If the name contains characters which are not allowed due to ruby naming rules, you can also use the methods`Setting[KEY]` resp. `Setting.get(KEY)` to get a setting's value and `Setting[KEY] = VALUE` resp.`Setting.create_or_update(KEY, VALUE)`.

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
Setting.create_or_update(:meaning_of_life, 42)
```

### Globally defined settings with types and validations

As stated above, the initializer will generate a file called `settings.yml` in your application's `config` directory. This file is used to define global settings, an entry consists of:

-	The setting's name
-	The setting's type (optional)
-	Validations to be performed when the setting is saved (optional)
-	A default value (optional)

An example would be a simple string setting:

```yaml
a_string:
  type: string
  default: "I am a string!"
  validations:
    presence: true
```

If a setting is defined with a type, automatic type conversion will happen, similar to what ActiveRecord does:

```ruby
Setting.a_string = 42
#=> "42"
```

The default value is used by the functions `Setting.get_or_default` and `Setting.create_default_setting` and a fallback option for assigned settings (see below).

The built-in validations currently support, this might be extended in the future.

| Base Validation | Options                    |
|:----------------|:---------------------------|
| `presence`      | `allow_nil`, `allow_blank` |
| `numericality`  | `only_integer`             |
| `boolean`       | &nbsp;                     |


### Assigned Records

Both globally defined settings and "anonymous" settings can also be assigned to
a instances of `ActiveRecord::Base` without having to define them in the model first.

An example would be the above mentioned saving of "items per page" values for
various views: Let's say we have an events view and want to save how many
rows/items each user would like to display.

As there might be many views requiring this functionality, it wouldn't make
sense to define global settings for each of them. Instead, we would use anonymous
settings with a generated key based on the current view:

```ruby
def items_per_page
  key           = [controller_path, action_name].join('_')
  default_value = 30
  Setting.get(key, current_user) || default_value
end
```

ActiveRecord Integration
------------------------

The gem adds the method `setting_accessor` to each class which inherits from `ActiveRecord::Base`.

`setting_accessor` takes a setting name and a set of options to customize the accessor's behaviour:

```ruby
class MyModel < ActiveRecord::Base
  setting_accessor :a_string, :fallback => :default
end
```

This automatically adds most of the helper methods to the model instances which are available for database columns:

```ruby
my_model          = MyModel.new

#Setter
my_model.a_string = 1234

#Getter
my_model.a_string
#=> "1234"

#Value before type cast
my_model.a_string_before_type_cast
#=> 1234

#Old value
my_model.a_string_was
#=> "I am a string!" (fallback value, see below)

#Check if the value was changed
my_model.a_string_changed?
#=> true
```

The setting records are only persisted if all settings *and* the main record were valid.

### Integration of globally defined settings

If a setting with the given name is defined in `config/settings.yml`, validations and type settings are automatically fetched from it, in this case, only the `:fallback` option is allowed.

As of now, this means that custom validations are also not supported for globally defined settings, this may be changed in the future.

### Class-wise definition of settings

If a setting is defined using `setting_accessor` which is not part of `config/settings.yml`, it will only be available in this class. It however may be defined in multiple classes independently.

Defining a class setting accepts the same options as the config file:

```ruby
class MyModel < ActiveRecord::Base
  setting_accessor :my_setting, :type => :boolean, :default => false
end
```

### Options

```ruby
:type => :string | :integer | :boolean | :polymorphic
```

`:type` defines the setting's data type. If no type is given, `:polymorhpic`
is used automatically.

For every other type, the setting's value is automatically converted accordingly
upon setting it, mimicking ActiveRecord's behaviour regarding database columns.
Please note that `:polymorphic` values are saved as is, meaning that you can
store everything that's serializable.

More types will be added in the future, most likely all database types
ActiveRecord can handle as well.

```ruby
:default => "I am a string!"
```

`:default` sets the setting's default value. It can be retrieved either by
calling `Setting.get_or_default(...)` or defining a `:fallback` on a class setting.

```ruby
:fallback => :global | :default | Object
```

The `:fallback` option specifies which value should be returned in case the
setting did not receive a value yet:

- `:global` will try to retrieve a global setting (`Setting.NAME`) with the same
  name as the accessor and return `nil` if it isn't defined.
- `:default` will return the default value set up either in the accessor method
  or `config/settings.yml` for globally defined settings.
- Every other value will be returned as is


```ruby
:validations => {:presence => true}
:validations => {:numericality => {:only_integer => true}}
:validations => {:custom => [lambda {|setting| setting.errors.add(:not_42) if setting.value != 42}]}
:validations => {:custom => [:must_be_42]}
```

There are some built-in validations (see above), but you may also define custom
validations either by passing in anonymous functions or symbols representing
class methods either in the setting class or the assigned model.

Contributing
------------

1.	Fork it ( https://github.com/stex/setting_accessors/fork )
2.	Create your feature branch (`git checkout -b my-new-feature`\)
3.	Commit your changes (`git commit -am 'Add some feature'`\)
4.	Push to the branch (`git push origin my-new-feature`\)
5.	Create a new Pull Request
