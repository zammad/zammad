# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::User::Initiator < Sequencer::Unit::Common::Provider::Named

  uses :login

  private

  def initiator
    return false if login.blank?

    login == Setting.get('import_kayako_endpoint_username')
  end
end
