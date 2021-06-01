# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Common::Model::Lookup::ExternalSync, sequencer: :unit do

  it 'finds model_class instance by remote_id' do
    user                 = create(:user)
    external_sync_source = 'test'
    remote_id            = '1337'

    ExternalSync.create(
      source:    external_sync_source,
      source_id: remote_id,
      o_id:      user.id,
      object:    user.class,
    )

    provided = process(
      remote_id:            remote_id,
      model_class:          user.class,
      external_sync_source: external_sync_source,
    )

    expect(provided[:instance]).to eq(user)
  end
end
