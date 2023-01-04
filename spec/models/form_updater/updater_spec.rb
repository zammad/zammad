# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormUpdater::Updater) do
  it 'checks that form updater supports a list' do
    expect(described_class.updaters.sort_by(&:name)).to include(FormUpdater::Updater::Ticket::Create,
                                                                FormUpdater::Updater::User::Create,
                                                                FormUpdater::Updater::User::Edit,
                                                                FormUpdater::Updater::Organization::Edit)
  end
end
