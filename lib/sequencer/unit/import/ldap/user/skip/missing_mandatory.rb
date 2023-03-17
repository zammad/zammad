# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::User::Skip::MissingMandatory < Sequencer::Unit::Import::Common::Model::Skip::MissingMandatory::Mapped
  private

  def mandatory
    [:login]
  end
end
