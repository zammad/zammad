# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormUpdater::Updater) do
  let(:available_updaters) do
    [
      FormUpdater::Updater::Ticket::Create,
      FormUpdater::Updater::User::Add,
      FormUpdater::Updater::User::Edit,
      FormUpdater::Updater::Organization::Edit
    ]
  end

  it 'lists all available form updaters' do
    expect(described_class.updaters.sort_by(&:name)).to eq(available_updaters.sort_by(&:name))
  end
end
