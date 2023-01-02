# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class PublicLinksController < ApplicationController
  include CanPrioritize

  prepend_before_action :authorize!, except: %i[show index]
  prepend_before_action :authentication_check, except: %i[show index]

  def index
    model_index_render(PublicLink, params)
  end

  def show
    model_show_render(PublicLink, params)
  end

  def create
    model_create_render(PublicLink, params)
  end

  def update
    model_update_render(PublicLink, params)
  end

  def destroy
    model_destroy_render(PublicLink, params)
  end
end
