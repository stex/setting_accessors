module SettingAccessors
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      argument :model_name, :type => :string, :default => 'Setting'

      def self.next_migration_number(path)
        if @prev_migration_nr
          @prev_migration_nr += 1
        else
          @prev_migration_nr = Time.now.utc.strftime('%Y%m%d%H%M%S').to_i
        end
        @prev_migration_nr.to_s
      end

      desc 'Installs everything necessary'
      def create_install
        template 'model.rb.erb', "app/models/#{model_name.classify.underscore}.rb"
        migration_template 'migration.rb.erb', "db/migrate/create_#{model_name.classify.underscore.pluralize}.rb"

        initializer 'setting_accessors.rb', <<INIT
SettingAccessors.configuration do |config|

  #The model your application is using for settings.
  #If you created it using the SettingAccessors generator, the
  #model name below should already be correct.
  config.setting_class = #{model_name}

end
INIT
      end
    end
  end
end
