# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Channel::Filter::IdentifySessionUser < Channel::Filter::BaseIdentifyUser
  def self.run(_channel, mail, _transaction_params)
    user = fetch_session_user(mail) || create_session_user(mail)

    mail[ :'x-zammad-session-user-id' ] = user.id
  end

  def self.fetch_session_user(mail)
    session_user_id = mail[ :'x-zammad-session-user-id' ]

    return if session_user_id.blank?

    session_user = User.lookup(id: session_user_id)

    if session_user
      Rails.logger.debug { "Took session form x-zammad-session-user-id header '#{session_user_id}'." }
    else
      Rails.logger.debug { "Invalid x-zammad-session-user-id header '#{session_user_id}', no such user - take user from 'from'-header." }
    end

    session_user
  end

  def self.create_session_user(mail)
    user_create(
      login:     mail[:from_email],
      firstname: mail[:from_display_name],
      lastname:  '',
      email:     mail[:from_email],
    )
  end
end
