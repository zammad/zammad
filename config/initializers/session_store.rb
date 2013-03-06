# Be sure to restart your server when you modify this file.

#Zammad::Application.config.session_store :cookie_store, :key => '_zammad_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
Zammad::Application.config.session_store :active_record_store, {
  :key => '_zammad_session_' + Digest::MD5.hexdigest(Rails.root.to_s).to_s[5..15]
}
