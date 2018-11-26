# Changelog

## 1.0.0

This is almost a complete refactoring of the gem which also removes some not really needed functionality.  
It is the first release fully compatible with Rails 5.  

New minimum versions:

* Ruby: 2.3
* Rails: 4.2

#### General

* Removed globally defined settings (`config/settings.yml`) and therefore also global validations and type conversions.  
  It is still possible to create global Settings, but each developer has to make sure that the assigned
  value is valid and correctly typed.
* Type conversion follows AR's type conversions more strictly now.  
  This means that e.g. assigning `1.0` to a boolean setting will result in `true` instead of `nil` as before.
* Updating an attribute created through `setting_accessor` now leads to the record being touched,  
  similar to what would happen when a normal database attribute was changed. (#4)
* Setting a new value for an attribute created through `attribute_accessor` will now mark
  the record as "dirty", meaning `changed?` returns true. (#9)  
  This was especially needed for Rails 5 as it only even performs a database operation in this case.  

#### Tests

* Tests are now written in RSpec
* The dummy Rails application has been removed and replaced with `with_model`
* Appraisal was added to test against multiple Rails versions

#### API Changes

* `method_missing` is now part of the SettingScaffold and therefore no longer needed in the actual Setting model.  
   You should remove `method_missing` from your model.
* Setting.create_or_update was renamed to Setting.set and now uses a keyword argument for `assignable`
* `setting_accessor` no longer supports the `fallback` option.  
   If a `default` option is given, it is automatically used as fallback.

## 0.3.0

* Fixed a bug that caused setting accessors not being initialized when being called as part of a rake task chain (#6)
