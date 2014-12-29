# require 'test_helper'
require 'open-uri'
require 'setting_accessors/mailman'

class TestMailerTest < ActionMailer::TestCase

  #----------------------------------------------------------------
  #                     Email Generation Testing
  #----------------------------------------------------------------

  context 'ActionMailer::Base.deliver' do
    setup do
      #@todo: Check if there is a way to set this in the dummy application itself,
      #       neither config/application.rb nor config/environments/* seems to be working.
      ActionMailer::Base.delivery_method = :activerecord

      #Make sure there is not yet an email record in the database (test test)
      assert !Email.first
    end

    should 'create a new email record in the database' do
      assert TestMailer.basic_email.deliver
      assert email      = Email.first,               'No new record was created'
      assert email.from = 'from@example.com',        "Wrong sender email address set: #{email.from}"
      assert email.to   = 'basic_email@example.com', "Wrong recipient email address set: #{email.to}"
    end

    should 'set custom delivery times in the created email record' do
      assert TestMailer.delayed_email.deliver
      assert email = Email.first
      assert email.delivery_time

      #As we don't know how fast these tests run through, we simply check
      #the generated delivery time with an error margin of 1 minute
      assert email.delivery_time >= (Time.now + 1.hour + 59.minutes)
      assert email.delivery_time <= (Time.now + 2.hours)
    end

    should 'set custom SMTP settings in the email record' do
      assert TestMailer.custom_smtp_email.deliver
      assert email = Email.first
      assert email.smtp_settings
      assert_equal email.smtp_settings, {
          :address   => 'localhost',
          :port      => 25,
          :domain    => 'localhost.localdomain',
          :user_name => 'some.user',
          :password  => 'some.password',
          :authentication => :plain,
          :enable_starttls_auto => true
      }
    end

    should 'set custom attributes in the email record' do
      assert TestMailer.custom_attribute_email.deliver
      assert email = Email.first
      assert_equal 42, email.a_number
    end
  end

  #----------------------------------------------------------------
  #                         SMTP Testing
  #----------------------------------------------------------------

  context 'Email sending' do
    setup do
      ActionMailer::Base.delivery_method = :activerecord
      if mailcatcher_running?
        setup_mailcatcher_settings
        @old_email_count = received_emails.size
      else
        puts 'Mailcatcher is not running, SMTP tests are skipped'
      end
    end

    should 'send out basic emails correctly' do
      if mailcatcher_running?
        assert TestMailer.basic_email.deliver
        run_ar_sendmail
        assert_equal @old_email_count + 1, received_emails.count, 'Email was not sent to local SMTP server'
      end
    end

  end

  private

  #
  # Executes ar_sendmail to send deliverable emails
  #
  def run_ar_sendmail
    run_options = {
        :chdir => Rails.root,
        :rails_env => 'test',
        :log_level => 'debug'
    }
    ArMailerRevised::Mailman.new(run_options).run
  end

  #
  # @return [Boolean] +true+ if mailcatcher is running
  #
  def mailcatcher_running?
    begin
      open('http://localhost:1080')
      true
    rescue Errno::ECONNREFUSED
      false
    end
  end

  def setup_mailcatcher_settings
    ActionMailer::Base.smtp_settings = {
        :address   => 'localhost',
        :port      => 1025,
        :domain    => 'localhost.localdomain',
        :user_name => 'some.user',
        :password  => 'some.password',
        :authentication => :plain,
        :enable_starttls_auto => true
    }
  end

  #
  # @return [Array<Hash>] Message Meta-Data for all received emails
  #
  def received_emails
    json = open('http://localhost:1080/messages')
    JSON.load(json)
  end
end
