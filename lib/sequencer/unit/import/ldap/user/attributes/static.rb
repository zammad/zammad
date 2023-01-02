# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::User::Attributes::Static < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_any_action

  uses :ldap_config

  def process
    provide_mapped do
      {
        # we have to add the active state manually
        # because otherwise disabled instances won't get
        # re-activated if they should get synced again
        active: true,

        # Set the source to 'Ldap' for the authentication handling.
        source: "Ldap::#{ldap_config[:id]}",
      }
    end
  end
end
