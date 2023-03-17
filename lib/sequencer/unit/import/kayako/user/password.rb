# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::User::Password < Sequencer::Unit::Common::Provider::Named

  uses :initiator

  private

  def password
    # set the used import key as the admin password
    # since we have no other confidential value
    # that is known to Zammad and the User
    return Setting.get('import_kayako_endpoint_password') if initiator

    # otherwise set an empty password so the user
    # has to re-set a new password for Zammad
    ''
  end
end
