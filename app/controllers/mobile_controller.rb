# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class MobileController < ApplicationController
  def index
    render(layout: 'layouts/mobile')
  end
end
