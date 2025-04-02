# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::User::Mapping < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :resource, :login, :password, :roles, :group_ids, :organization_id, :identifier

  def process
    provide_mapped do
      {
        login:           login,
        firstname:       resource['full_name'],
        lastname:        '', # makes sure name guessing is triggered for updating existing users.
        email:           identifier[:email],
        phone:           identifier[:phone],
        password:        password,
        active:          active?,
        group_ids:       group_ids,
        roles:           roles,
        organization_id: organization_id,
        last_login:      resource['last_logged_in_at'],
      }
    end
  end

  private

  def active?
    resource['is_enabled']
  end
end
