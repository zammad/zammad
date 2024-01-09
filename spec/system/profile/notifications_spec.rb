# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
      find('input[name="matrix.escalation.channel"]', visible: :all).click

      find('#content_permanent_Profile form .btn--primary').click

      await_empty_ajax_queue

      expect(user.reload.preferences).to include(
        notification_config: include(
          matrix: include(
            escalation: include(
              criteria: include(owned_by_me: false),
              channel:  include(email: false, online: true)
            ),
            update:     include(
              criteria: include(owned_by_me: true),
              channel:  include(email: true, online: true)
            )
          )
        )
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

  describe 'limiting notifications by groups' do
    let(:group_a) { create(:group) }
    let(:group_b) { create(:group) }

    context 'when limit is not enabled' do
      before do
        user.update! groups: [group_a, group_b]

        visit 'profile/notifications'
      end

      it 'allows to limit notifications in specific groups' do
        expect(find('#profile-groups-limit', visible: :all)).not_to be_checked

        click '.zammad-switch'

        find('#content_permanent_Profile form .btn--primary').click

        await_empty_ajax_queue

        expect(user.reload.preferences).to include(
          notification_config: include(
            group_ids: [group_a.id.to_s, group_b.id.to_s]
          )
        )

        expect(find('#profile-groups-limit', visible: :all)).to be_checked
      end
    end

    context 'when limit is enabled' do
      before do
        user.groups = [group_a, group_b]
        user.preferences[:notification_config][:group_ids] = [group_a.id.to_s]
        user.save!

        visit 'profile/notifications'
      end

      it 'clears groups limit' do
        expect(find('#profile-groups-limit', visible: :all)).to be_checked

        click '.zammad-switch'

        find('#content_permanent_Profile form .btn--primary').click

        await_empty_ajax_queue

        expect(user.reload.preferences[:notification_config]).not_to have_key(:group_ids)

        expect(find('#profile-groups-limit', visible: :all)).not_to be_checked
      end

      it 'clears limit when all groups are unchecked' do
        expect(find('#profile-groups-limit', visible: :all)).to be_checked

        expect(page).to have_no_text('Disabling the notifications from all groups will turn off the limit.')

        find("input[name='group_ids'][value='#{group_a.id}']", visible: :all).click

        expect(page).to have_text('Disabling the notifications from all groups will turn off the limit.')

        find('#content_permanent_Profile form .btn--primary').click

        await_empty_ajax_queue

        expect(user.reload.preferences[:notification_config]).not_to have_key(:group_ids)

        expect(find('#profile-groups-limit', visible: :all)).not_to be_checked
      end
    end
  end
end
