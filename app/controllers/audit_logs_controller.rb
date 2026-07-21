# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AuditLogsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    model_index_render(AuditLog, params)
  end

  def show
    model_show_render(AuditLog, params)
  end

  def search
    model_search_render(AuditLog, params)
  end
end
