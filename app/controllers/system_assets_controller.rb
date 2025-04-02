# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SystemAssetsController < ApplicationController
  def show
    backend = Service::SystemAssets.backend params[:identifier]

    raise ActiveRecord::RecordNotFound if !backend

    asset = backend.sendable_asset

    send_data(
      asset.content,
      filename:    asset.filename,
      type:        asset.type,
      disposition: 'inline'
    )

    expires_in 1.year, public: true
  end
end
