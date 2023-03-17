# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::User::Skip::IsLdapSource < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_any_action

  uses :instance
  provides :action

  def process
    return if !Setting.get('ldap_integration')

    ldap_source = LdapSource.by_user(instance)
    return if ldap_source.nil?
    return if !ldap_source.active?

    logger.info { "Skipping. Found an existing user for login '#{instance.login}' synced by LDAP." }

    state.provide(:action, :skipped)
  end
end
