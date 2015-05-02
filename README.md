SettingAccessors
================

Sometimes it's handy to keep track of various settings or attributes in ActiveRecord instances and persist them through various requests (and sessions). An example would be to store a items-per-page value for multiple tables in the application per user or probably also set default sorting directions.

The only problem is, that it would be necessary to either keep hundreds of columns in the corresponding table or create a serialized attribute which would grow over time and generally be hard to manage.

This gem consists of a global key-value-store, allowing to use both global and record bound settings.

Installation
------------

Add this line to your application's Gemfile:

```
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

Usage
-----

In the following, the model name will be assumed as `Setting`, though you may choose its name freely using the provided generator (see above).

Settings can either be global or assigned to an instance of ActiveRecord::Base. They consist of a name which is unique either in the global scope or within the instance and a value which can be everything that's serializable through YAML.

### Usage as global key-value-store without predefined settings

The easiest way to use the settings model is as a global key-value-store without validations and typecasting.

Values can be easily set and retrieved by using their names as class method names on `Setting` itself:

```
Setting.the_meaning_of_life = 42
Setting.the_meaning_of_life
#=> 42
```

If the name contains characters which are not allowed due to ruby naming rules, you can also use the methods`Setting[KEY]` resp. `Setting.get(KEY)` to get a setting's value and `Setting[KEY] = VALUE` resp.`Setting.create_or_update(KEY, VALUE)`.

Therefore, the following getter methods are equivalent:

```
Setting.meaning_of_life
Setting[:meaning_of_life]
Setting.get(:meaning_of_life)
```

For the corresponding setters:

```
Setting.meaning_of_life = 42
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

```
a_string:
  type: string
  default: "I am a string!"
  validations:
    presence: true
```

If a setting is defined with a type, automatic type conversion will happen, similar to what ActiveRecord does:

```
Setting.a_string = 42
#=> "42"
```

The default value is used by the functions `Setting.get_or_default` and `Setting.create_default_setting` and a fallback option for assigned settings (see below).

Validations currently only support

| Base Validation | Options                    |
|:----------------|:---------------------------|
| `presence`      | `allow_nil`, `allow_blank` |
| `numericality`  | `only_integer`             |
| `boolean`       |                            |

Contributing
------------

1.	Fork it ( https://github.com/stex/setting_accessors/fork )
2.	Create your feature branch (`git checkout -b my-new-feature`\)
3.	Commit your changes (`git commit -am 'Add some feature'`\)
4.	Push to the branch (`git push origin my-new-feature`\)
5.	Create a new Pull Request
