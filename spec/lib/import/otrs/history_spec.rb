# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/otrs/history_examples'

RSpec.describe Import::OTRS::History do

  let(:start_import_test) { described_class.new(object_structure) }
  let(:object_structure) { load_history_json('article/default') }

  it 'requires an implementation of init_callback' do
    expect do
      start_import_test
    end.to raise_error(RuntimeError)
  end
end
