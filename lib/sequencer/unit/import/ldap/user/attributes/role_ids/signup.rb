# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::User::Attributes::RoleIds::Signup < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  skip_any_action

  uses :mapped, :ldap_config

  def process
    # return if a mapping entry was found
    return if mapped[:role_ids].present?

    # return if no general mapping is configured
    # to let Zammad be the leading source of
    # Role assignments
    return if ldap_config[:group_role_map].blank?

    # LDAP is the leading source if
    # a mapping entry is present
    provide_mapped do
      {
        role_ids: Role.signup_roles.map(&:id)
      }
    end
  end
end
