# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Ldap::User::Attributes::RoleIds::Signup, sequencer: :unit do

  it "doesn't provide mapped role_ids if already provided" do

    ldap_config = {
      group_role_map: {
        'a' => 'b'
      }
    }

    mapped = {
      role_ids: [1, 2]
    }

    provided = process(
      ldap_config:     ldap_config,
      mapped:          mapped,
      signup_role_ids: [3],
    )

    expect(provided[:mapped][:role_ids]).to eq(mapped[:role_ids])
  end

  it "doesn't provide mapped role_ids if no LDAP Group <-> Zammad Role mapping is configured" do

    ldap_config = {
      group_role_map: {}
    }

    provided = process(
      ldap_config:     ldap_config,
      mapped:          {},
      signup_role_ids: [3],
    )

    expect(provided[:mapped]).not_to have_key(:role_ids)
  end

  it 'ensures Signup Roles if no mapped role_ids are assigned' do

    ldap_config = {
      group_role_map: {
        'a' => 'b'
      }
    }

    provided = process(
      ldap_config:     ldap_config,
      mapped:          {},
      signup_role_ids: [3],
    )

    expect(provided[:mapped][:role_ids]).to eq([3])
  end
end
