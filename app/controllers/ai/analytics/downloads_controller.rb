# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
                raise Exceptions::UnprocessableContent, 'invalid report type'
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

  DIRECT_FILTERS = %i[
    related_object_type
    related_object_id
    ai_service_name
    triggered_by_type
    triggered_by_id
  ].freeze

  DATE_FILTERS = %i[
    created_after
    created_before
  ].freeze

  def scope
    filters = params.permit(filters: (DIRECT_FILTERS + DATE_FILTERS))[:filters] || {}

    scope = AI::Analytics::Run.all

    DIRECT_FILTERS.each do |filter|
      scope = scope.where(filter => filters[filter]) if filters[filter].present?
    end

    created_after  = parse_date(filters[:created_after])
    created_before = parse_date(filters[:created_before])

    scope = scope.where(created_at: (created_after)..) if created_after
    scope = scope.where(created_at: ..(created_before)) if created_before

    scope
  end

  # Ignore blank or unparseable date filters instead of letting them cast to
  #   NULL in the query, which would silently match no records.
  def parse_date(value)
    return if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end
