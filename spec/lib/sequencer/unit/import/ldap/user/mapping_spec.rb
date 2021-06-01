# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

    expect(provided['lastname']).to be_nil
  end
end
