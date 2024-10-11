# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'Taskbar::List' do
  let(:user) { create(:user) }

  describe '.list' do

    context 'with entity restriction' do
      before do
        create_list(:taskbar, 2, user:)
        create(:taskbar, user: user, callback: 'Unknown')
      end

      it 'check for correct count' do
        expect(Taskbar.list(user, restrict_entities: true).count).to be 2
      end
    end
  end
end
