# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class PackagesController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  # GET /api/v1/packages
  def index
    packages = Package.all.order('name')
    commands = ['rails zammad:package:migrate', 'rails assets:precompile']
    if File.exist?('/usr/bin/zammad')
      commands.map! { |s| "zammad run #{s}" }
    end
    render json: {
      packages: packages,
      commands: commands
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
