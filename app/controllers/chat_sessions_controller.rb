# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ChatSessionsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def show
    model_show_render(Chat::Session, params)
  end

end
