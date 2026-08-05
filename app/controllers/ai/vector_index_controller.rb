# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::VectorIndexController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def sync
    VectorIndexSyncJob.perform_later

    render json: { success: true }
  end
end
