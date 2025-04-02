# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SystemReportController < ApplicationController

  prepend_before_action :authenticate_and_authorize!

  # GET /api/v1/system_report
  def index
    render json: {
      descriptions: SystemReport.descriptions,
      fetch:        SystemReport.fetch
    }
  end

  # GET /api/v1/system_report/download
  def download
    instance = SystemReport.fetch_with_create

    send_data(
      instance.data.to_json,
      filename:    instance.filename,
      type:        'application/json',
      disposition: 'attachment'
    )
  end

  # GET /api/v1/system_report/plugins
  def plugins
    render json: { plugins: SystemReport.plugins }
  end

end
