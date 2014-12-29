#
# Class used as email model for ArMailerRevised
#
# @attr [String] from
#   The email sender
#
# @attr [String] to
#   The email recipient
#
# @attr [Integer] last_send_attempt
#   Unix timestamp containing the last time the system tried to deliver this email.
#   The value will be +nil+ if there wasn't a send attempt yet
#
# @attr [String] mail
#   The mail body, including the mail header information (from, to, encoding, ...)
#
# @attr [Date] delivery_date
#   If this is set, the email won't be sent before the given date.
#
# @attr [Hash] smtp_settings
#   Serialized Hash storing custom SMTP settings just for this email.
#   If this value is +nil+, the system will use the default SMTP settings set up in the application
#

class Email < ActiveRecord::Base
  #Helper methods and named scopes provided by ArMailerRevised
  include ArMailerRevised::EmailScaffold



end