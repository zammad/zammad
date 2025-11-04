# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AITextToolsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    model_index_render(AI::TextTool, params)
  end

  def show
    model_show_render(AI::TextTool, params)
  end

  def create
    model_create_render(AI::TextTool, params)
  end

  def update
    model_update_render(AI::TextTool, params)
  end

  def search
    model_search_render(AI::TextTool, params)
  end

  def destroy
    model_destroy_render(AI::TextTool, params)
  end
end
