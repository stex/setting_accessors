class TestMailer < ActionMailer::Base
  default from: 'from@example.com'

  def basic_email
    mail(to: 'basic_email@example.com', subject: 'Basic Email Subject', body: 'Basic Email Body')
  end

  def delayed_email
    ar_mailer_delivery_time Time.now + 2.hours
    mail(to: 'delayed_email@example.com', subject: 'Delayed Email Subject', :body => 'Delayed Email Body')
  end

  def custom_smtp_email
    ar_mailer_smtp_settings({
      :address   => 'localhost',
      :port      => 25,
      :domain    => 'localhost.localdomain',
      :user_name => 'some.user',
      :password  => 'some.password',
      :authentication => :plain,
      :enable_starttls_auto => true
    })

    mail(to: 'custom_smtp_email@example.com', subject: 'Custom SMTP Email Subject', :body => 'Custom SMTP Email Body')
  end

  def custom_attribute_email
    ar_mailer_attribute :a_number, 42
    mail(to: 'custom_attribute_email@example.com', subject: 'Custom Attribute Email Subject', :body => 'Custom Attribute Email Body')
  end

end
