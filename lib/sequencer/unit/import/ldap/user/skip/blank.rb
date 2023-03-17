# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::User::Skip::Blank < Sequencer::Unit::Import::Common::Model::Skip::Blank::Mapped
  private

  def ignore
    %i[login]
  end
end
