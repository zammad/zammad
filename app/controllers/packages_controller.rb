# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class PackagesController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  # GET /api/v1/packages
  def index
    render json: {
      packages:             Package.reorder('name'),
      package_installation: Package.app_package_installation?,
      local_gemfiles:       Package.gem_files?,
      token_setting_id:     Setting.find_by(name: 'packages_token').id,
      token_present:        Setting.get('packages_token').present?,
      api_package_metas:    api_package_metas,
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

  # POST /api/v1/packages/api
  def install_api
    api_package = api_packages[params[:id]]
    raise "Can not find package '#{params[:id]}'!" if api_package.blank?

    Package.install(string: api_package.to_json)
    render json: {
      success: true
    }
  end

  # PUT /api/v1/packages/api
  def update_api
    package = Package.find(params[:id])

    api_package = api_packages[package.name]
    raise "Can not find package '#{package.name}'!" if api_package.blank?

    Package.install(string: api_package.to_json)
    render json: {
      success: true
    }
  end

  private

  def api_packages
    @api_packages ||= Package.api_packages_hash({ version_name: Package.api_version_name })
  end

  def api_package_metas
    api_packages.transform_values do |value|
      value.slice('name', 'version', 'vendor', 'license', 'url', 'change_log', 'description')
    end
  end

end
