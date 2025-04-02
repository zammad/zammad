# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue5390TaskbarRemoveDuplicatedKeyByUser, db_strategy: :reset, type: :db_migration do
  before { without_index(:taskbars, column: %i[user_id key app]) }

  context 'when some user have duplicated taskbar key entries' do
    let(:user)        { create(:user) }
    let(:second_user) { create(:user) }
    let(:other_user)  { create(:user) }

    let(:taskbars) do
      create_list(:taskbar, 2, user_id: user.id)
    end

    let(:second_user_taskbar) do
      create(:taskbar, user_id: second_user.id, last_contact: 1.day.ago)
    end

    before do
      create_list(:taskbar, 2, user_id: other_user.id)

      second_duplicate_taskbar = build(:taskbar, user_id: second_user.id, key: second_user_taskbar.key, last_contact: 1.minute.from_now)
      second_duplicate_taskbar.save!(validate: false)

      duplicate_taskbar = build(:taskbar, user_id: user.id, key: taskbars.first.key)
      duplicate_taskbar.save!(validate: false)
    end

    it 'remove duplicated taskbar entries' do
      expect { migrate }.to change(Taskbar, :count).by(-2)
    end

    it 'remove oldest taskbar entry' do
      migrate

      expect(Taskbar.find_by(id: second_user_taskbar.id)).to be_nil
    end
  end
end
