# Copyright (C) 2012-2017 Zammad Foundation, http://zammad-foundation.org/

class VersionController < ApplicationController
  prepend_before_action { authentication_check(permission: 'admin.version') }

  # GET /api/v1/version
  def index
    render json: {
      version: Version.get
    }
  end

end
