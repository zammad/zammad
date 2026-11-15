# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Ldap::User::Mapping, sequencer: :unit do

  it 'ensures to unset attribute value if none is provided' do

    ldap_config = {
      user_attributes: {
        firstName:      'firstname',
        lastName:       'lastname',
        samaccountname: 'login',
      }
    }

    resource = {
      samaccountname: 'Some41',
      firstName:      'Some',
    }

    provided = process(
      ldap_config: ldap_config,
      resource:    resource,
    )

    expect(provided[:mapped]['lastname']).to be_nil
  end

  it 'maps one LDAP attribute to multiple Zammad attributes' do

    ldap_config = {
      user_attributes: {
        mail:      %w[login email],
        firstName: 'firstname',
      }
    }

    resource = {
      mail:      'some@example.com',
      firstName: 'Some',
    }

    provided = process(
      ldap_config: ldap_config,
      resource:    resource,
    )

    expect(provided[:mapped]).to include(
      'login'     => 'some@example.com',
      'email'     => 'some@example.com',
      'firstname' => 'Some',
    )
  end
end
