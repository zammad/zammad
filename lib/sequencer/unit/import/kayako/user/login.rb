# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::User::Login < Sequencer::Unit::Common::Provider::Named

  uses :identifier

  private

  def login
    # Check the differnt identifier types
    identifier[:email] || identifier[:phone] || identifier[:twitter] || identifier[:facebook]
  end
end
