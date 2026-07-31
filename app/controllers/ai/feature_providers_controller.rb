# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::FeatureProvidersController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    model_index_render(AI::FeatureProvider, params)
  end

  def show
    model_show_render(AI::FeatureProvider, params)
  end

  def create
    model_create_render(AI::FeatureProvider, params)
  end

  def update
    # identifier is set at create time and must not be changed via update.
    params.delete(:identifier)
    model_update_render(AI::FeatureProvider, params)
  end

  def destroy
    model_destroy_render(AI::FeatureProvider, params)
  end
end
