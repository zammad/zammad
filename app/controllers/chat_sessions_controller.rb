# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class ChatSessionsController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  def show
    model_show_render(Chat::Session, params)
  end

end
