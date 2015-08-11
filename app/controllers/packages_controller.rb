# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class PackagesController < ApplicationController
  before_action :authentication_check

  # GET /api/v1/packages
  def index
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    packages = Package.all().order('name')
    render json: {
      packages: packages
    }
  end

  # POST /api/v1/packages
  def install
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    Package.install( string: params[:file_upload].read )

    redirect_to '/#system/package'
  end

  # DELETE /api/v1/packages
  def uninstall
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    package = Package.find( params[:id] )

    Package.uninstall( name: package.name, version: package.version )

    render json: {
      success: true
    }
  end

end
