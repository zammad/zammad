# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe '.merge', searchindex: true, type: :model do
  let(:user_1) { create(:agent, groups: Group.all) }
  let(:user_2) { create(:agent, groups: Group.all) }
  let(:ticket_1) do
    ticket = create(:ticket, owner: user_1, group: Group.first)
    create(:mention, mentionable: ticket, user: user_1)
    create(:mention, mentionable: ticket, user: user_2)
    ticket
  end

  before do
    user_1
    user_2
    ticket_1
  end

  it 'does merge users' do
    expect { user_2.merge(user_1.id) }.not_to raise_error
  end
end
