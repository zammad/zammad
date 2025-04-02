# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Settings::TicketAgentDefaultNotificationsController, authenticated_as: :user, type: :request do
  let(:user) { create(:admin) }

  describe '#apply_to_all', performs_jobs: true do
    it 'schedules a background job' do
      expect do
        post '/api/v1/settings/ticket_agent_default_notifications/apply_to_all', params: {}, as: :json
      end.to have_enqueued_job(ResetNotificationsPreferencesJob).with(send_to_when_done: user.id)
    end
  end
end
