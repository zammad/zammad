# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'history'

def history_from_json(file, zammad_structure)
  expect(History).to receive(:add).with(zammad_structure)
  described_class.new(load_history_json(file))
end

def load_history_json(file)
  json_fixture("import/otrs/history/#{file}")
end

RSpec.shared_examples 'Import::OTRS::History' do
  it 'responds to init_callback' do
    expect(::History).to receive(:add)
    allow(::History::Attribute).to receive(:exists?).and_return(true)
    blank_instance = described_class.new({})
    expect(blank_instance).to respond_to('init_callback')
  end
end
