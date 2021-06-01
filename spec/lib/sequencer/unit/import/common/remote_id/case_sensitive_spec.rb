# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Common::RemoteId::CaseSensitive, sequencer: :unit do

  it 'overwrites the remote_id with the the SHA-2 hashed version of it' do

    remote_id = 'Zammad!'
    hashed    = '07071585f063b37b8288021f541d8c3cee3265f34e258c8b0bd926378ce03c97'

    provided = process(
      remote_id: remote_id,
    )

    expect(provided[:remote_id]).to eq(hashed)
  end
end
