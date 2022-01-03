# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class MobileController < ApplicationController
  def index
    render(layout: 'layouts/mobile')
  end
end
