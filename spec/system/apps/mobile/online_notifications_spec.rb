# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Online Notifications', app: :mobile, authenticated_as: :user, type: :system do
  context 'when looking at notifications' do
    let(:notification) { create(:online_notification, user: user, created_by: user, type_name: 'update') }
    let(:user)         { create(:admin, :groupable, group: Ticket.first.group) }

    before { notification }

    it 'shows notification' do
      visit '/notifications'

      wait_for_gql('shared/entities/online-notification/graphql/queries/onlineNotifications.graphql')

      expect(page).to have_text('updated ticket')
    end
  end
end
