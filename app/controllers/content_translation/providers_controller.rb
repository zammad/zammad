# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ContentTranslation::ProvidersController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def activate
    switch(active: true)
  end

  def deactivate
    switch(active: false)
  end

  private

  def switch(active:)
    Service::ContentTranslation::SwitchProvider.execute(provider: params[:provider], active:)

    render json: { success: true }
  end
end
