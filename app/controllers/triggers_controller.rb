# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TriggersController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  def index
    model_index_render(Trigger, params)
  end

  def show
    model_show_render(Trigger, params)
  end

  def create
    model_create_render(Trigger, params)
  end

  def update
    model_update_render(Trigger, params)
  end

  def destroy
    model_destroy_render(Trigger, params)
  end

end
