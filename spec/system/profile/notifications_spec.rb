# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Profile > Notifications', authenticated_as: :user, type: :system do
  let(:user) { create(:agent) }

  context 'with default notification settings' do
    before do
      visit 'profile/notifications'
    end

    it 'shows selected notifications' do
      user.preferences
        .dig('notification_config', 'matrix')
        .each do |key, value|
          expect(page).to have_field("matrix.#{key}.criteria.owned_by_me", checked: value[:criteria][:owned_by_me], visible: :all)
          expect(page).to have_field("matrix.#{key}.criteria.owned_by_nobody", checked: value[:criteria][:owned_by_nobody], visible: :all)
          expect(page).to have_field("matrix.#{key}.criteria.subscribed", checked: value[:criteria][:subscribed], visible: :all)
          expect(page).to have_field("matrix.#{key}.criteria.no", checked: value[:criteria][:no], visible: :all)
          expect(page).to have_field("matrix.#{key}.channel", checked: value[:channel][:email], visible: :all)
        end
    end

    it 'can change notifications' do
      find('input[name="matrix.escalation.criteria.owned_by_me"]', visible: :all).click

      find('#content_permanent_Profile form .btn--primary').click

      await_empty_ajax_queue

      expect(user.reload.preferences).to include(
        notification_config: include(matrix: include(escalation: include(criteria: include(owned_by_me: false))))
      )
    end
  end

  context 'with custom notification settings' do
    before do
      user.preferences[:notification_config][:matrix][:escalation][:criteria][:owned_by_me] = false
      user.save!

      visit 'profile/notifications'
    end

    it 'can reset notifications' do
      find('#content_permanent_Profile form .js-reset').click

      in_modal do
        click_on 'Yes'
      end

      expect(page).to have_field('matrix.escalation.criteria.owned_by_me', checked: true, visible: :all)

      expect(user.reload.preferences).to include(
        notification_config: include(matrix: include(escalation: include(criteria: include(owned_by_me: true))))
      )
    end
  end
end
