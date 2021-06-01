# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class PackagesController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  # GET /api/v1/packages
  def index
    packages = Package.all().order('name')
    render json: {
      packages: packages
    }
  end

  # POST /api/v1/packages
  def install
    Package.install(string: params[:file_upload].read)
    redirect_to '/#system/package'
  end

  # DELETE /api/v1/packages
  def uninstall
    package = Package.find(params[:id])
    Package.uninstall(name: package.name, version: package.version)
    render json: {
      success: true
    }
  end

end
