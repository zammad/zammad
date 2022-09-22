# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormUpdater::Updater) do
  it 'lists all available form updaters' do
    expect(described_class.updaters).to include(FormUpdater::Updater::Ticket::Create)
  end
end
