# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Exchange::FolderContact::HttpLog, sequencer: :unit do
  it 'logs unchanged contacts' do
    process(dry_run: false, action: :unchanged, remote_id: 'contact1337', mapped: { login: 'hans' }, exception: nil)
    expect(HttpLog.last).to have_attributes(facility: 'EWS', url: 'unchanged -> contact1337')
  end
end
