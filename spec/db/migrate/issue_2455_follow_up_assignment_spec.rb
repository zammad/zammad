# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue2455FollowUpAssignment, type: :db_migration do
  let!(:group) { create(:group, follow_up_assignment: false) }

  it 'sets groups to follow_up_assignment true' do
    expect { migrate }.to change { group.reload.follow_up_assignment }.to(true)
  end
end
