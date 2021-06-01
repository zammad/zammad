# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Ldap::User::RemoteId::Unhex, sequencer: :unit do

  it 'unhexes hexed UID remote_ids' do

    provided = process(
      remote_id: "a\xB3B\xF7\xC62\x92J\xBA\xAA\xEA\xAE}\xF6W\xEE",
    )

    expect(provided[:remote_id]).to eq('f742b361-32c6-4a92-baaa-eaae7df657ee')
  end

  it 'ignores not hexed remote_ids' do

    remote_id = 'f742b361-32c6-4a92-baaa-eaae7df657ee'

    provided = process(
      remote_id: remote_id,
    )

    expect(provided[:remote_id]).to eq(remote_id)
  end
end
