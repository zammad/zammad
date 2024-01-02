# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Settings::TicketAgentDefaultNotificationsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def apply_to_all
    ResetNotificationsPreferencesJob.perform_later(send_to_when_done: current_user.id)

    render json: { status: :ok }
  end
end
