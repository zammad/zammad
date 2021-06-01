# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Common::RemoteId::CaseInsensitive, sequencer: :unit do

  it 'overwrites the remote_id with the downcased version of it' do

    remote_id = 'SomeRandom@EmailExample.com'

    provided = process(
      remote_id: remote_id,
    )

    expect(provided[:remote_id]).to eq(remote_id.downcase)
  end
end
