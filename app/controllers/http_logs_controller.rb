# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class HttpLogsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  # GET /http_logs/:facility
  def index
    # No eager loading of :related_object on purpose: the polymorphic preload constantizes every
    # type it finds, so one stale row from a removed addon would raise for the whole page.
    # HttpLog.related_object_labels batches the lookups instead, skipping such rows.
    logs = HttpLogPolicy::Scope.new(current_user, HttpLog)
      .resolve(facility: params[:facility])
      .reorder(created_at: :desc).limit(params[:limit] || 50)
      .to_a

    # The label rides along so the log can name what it links to without the frontend having to
    # load every referenced record.
    labels = HttpLog.related_object_labels(logs)

    model_index_render_result(logs.map { |log| log.attributes.merge('related_object_label' => labels[log.id]) })
  end

  # POST /http_logs
  def create
    # The reference is set by whoever performs the request, never by an API caller: a crafted type
    # could otherwise point at any record and expose its name to an admin of a single facility.
    model_create_render(HttpLog, params.except(:related_object_type, :related_object_id))
  end

end
