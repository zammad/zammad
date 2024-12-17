# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class DataPrivacyTasksController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    model_index_render(DataPrivacyTask, params)
  end

  def by_state
    scope = DataPrivacyTask.reorder('id DESC').limit(500)

    in_process = scope.where(state: 'in process')
    failed     = scope.where(state: 'failed')
    completed  = scope.where(state: 'completed')

    assets = ApplicationModel::CanAssets.reduce [in_process, failed, completed].flatten, {}

    render json: {
      record_ids: {
        in_process: in_process.pluck(:id),
        failed:     failed.pluck(:id),
        completed:  completed.pluck(:id)
      },
      assets:     assets,
    }, status: :ok
  end

  def show
    model_show_render(DataPrivacyTask, params)
  end

  def create
    model_create_render(DataPrivacyTask, params)
  end

  def update
    model_update_render(DataPrivacyTask, params)
  end

  def destroy
    model_destroy_render(DataPrivacyTask, params)
  end

end
