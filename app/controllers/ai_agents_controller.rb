# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AIAgentsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    model_index_render(AI::Agent, params)
  end

  def show
    model_show_render(AI::Agent, params)
  end

  def create
    model_create_render(AI::Agent, params)
  end

  def update
    model_update_render(AI::Agent, params)
  end

  def search
    model_search_render(AI::Agent, params)
  end

  def destroy
    model_destroy_render(AI::Agent, params)
  end

  def types
    render json: AI::Agent::Type.available_type_data, status: :ok
  end
end
