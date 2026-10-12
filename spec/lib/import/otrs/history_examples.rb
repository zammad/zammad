# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

def history_from_json(file, zammad_structure)
  expect(History).to receive(:add).with(zammad_structure)
  described_class.new(load_history_json(file))
end

def load_history_json(file)
  json_fixture("import/otrs/history/#{file}")
end
