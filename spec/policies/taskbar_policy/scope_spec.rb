# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TaskbarPolicy::Scope do
  subject(:scope) { described_class.new(user, Taskbar) }

  let(:user) { create(:agent) }

  let(:taskbar)                    { create(:taskbar, user:, prio: 3) }
  let(:taskbar_2)                  { create(:taskbar, user:, prio: 1) }
  let(:taskbar_3)                  { create(:taskbar, user:, prio: 4) }
  let(:taskbar_nonexistant_entity) { create(:taskbar, callback: 'nonexistant', user:, prio: 2) }
  let(:taskbar_other_user)         { create(:taskbar, user: create(:agent)) }

  before do
    taskbar && taskbar_2 && taskbar_3
    taskbar_nonexistant_entity && taskbar_other_user
  end

  describe '#resolve' do

    it 'returns user taskbars ordered by prio and filtered to legit entities' do
      expect(scope.resolve).to eq([taskbar_2, taskbar, taskbar_3])
    end
  end
end
