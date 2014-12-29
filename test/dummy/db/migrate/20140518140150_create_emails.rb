class CreateEmails < ActiveRecord::Migration
  def change
    create_table :emails do |t|
      t.string   'from'
      t.string   'to'

      #Timestamp for the last send attempt, 0 means, that there was no send attempt yet
      t.integer  'last_send_attempt', :default => 0

      #Mail body including headers
      t.text     'mail'

      #Custom delivery time, ArMailer won't send the email prior to this time
      t.datetime 'delivery_time'

      #Custom SMTP settings per email
      t.text     'smtp_settings'

      t.integer  'a_number'

      #You can add further attributes here, they can then be assigned
      #to the email record using the +ar_mailer_attribute+ method from
      #within mailer methods. Example:
      #
      # In the migration:
      #  t.integer :client_id
      #
      # Inside the mailer method:
      #   ar_mailer_attribute :client_id, @client.id

      t.timestamps
    end
  end
end

