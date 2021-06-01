# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Ldap::User::Lookup::Attributes, sequencer: :unit do

  let(:model_class) { ::User }
  let(:external_sync_source) { 'test' }

  it 'finds entries via lookup attributes' do

    current_user = create(:user)

    provided = process(
      found_ids:            [],
      model_class:          model_class,
      external_sync_source: external_sync_source,
      mapped:               {
        login: current_user.login,
        email: current_user.email,
      }
    )

    expect(provided[:instance]).to eq(current_user)
  end

  it "doesn't find already synced/found entries with same lookup attributes" do

    other_user = create(:user)

    provided = process(
      found_ids:            [other_user.id],
      model_class:          model_class,
      external_sync_source: external_sync_source,
      mapped:               {
        login: other_user.login,
        email: other_user.email,
      }
    )

    expect(provided[:instance]).to be_nil
  end

  it "doesn't sync already synced users" do

    provided = process(
      found_ids:            [],
      model_class:          model_class,
      external_sync_source: external_sync_source,
      mapped:               {
        login: 'example.login',
        email: 'test@example.com',
      }
    )

    expect(provided[:instance]).to be_nil
  end

end
