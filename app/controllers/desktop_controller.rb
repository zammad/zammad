# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class DesktopController < ApplicationController
  def index
    render(layout: 'layouts/desktop', locals: { locale: current_user&.preferences&.dig(:locale) })
  end
end
