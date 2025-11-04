# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Analytics::DownloadsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def download
    format       = params[:format].presence || 'xlsx'
    filename     = "ai_analytics_#{params[:type]}.#{format}"
    content_type = case format
                   when 'xlsx' then ExcelSheet::CONTENT_TYPE
                   else 'application/json'
                   end

    content = case params[:type]
              when 'errors'
                Service::AI::Analytics::GenerateReport::Errors
              when 'with_usages'
                Service::AI::Analytics::GenerateReport::WithUsages
              else
                raise Exceptions::UnprocessableEntity, 'invalid report type'
              end
                 .new(scope:, format:)
                 .execute

    send_data(
      content,
      filename:,
      type:        content_type,
      disposition: 'attachment'
    )
  end

  private

  DIRECT_FILTERS = %i[related_object_type related_object_id ai_service_name].freeze
  DATE_FILTERS = %i[created_after created_before].freeze

  def scope
    filters = params.permit(filters: (DIRECT_FILTERS + DATE_FILTERS))[:filters] || {}

    scope = AI::Analytics::Run.all

    DIRECT_FILTERS.each do |filter|
      scope = scope.where(filter => filters[filter]) if filters[filter].present?
    end

    scope = scope.where(created_at: (filters[:created_after])..) if filters[:created_after].present?
    scope = scope.where(created_at: ..(filters[:created_before])) if filters[:created_before].present?

    scope
  end
end
