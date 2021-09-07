# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CanPaginate::Pagination

  def initialize(params, default: nil, max: nil)
    @params  = params
    @default = default.presence || 100
    @max     = max.presence || 500
  end

  def limit
    limit = @params[:per_page] || @params[:limit] || @default

    [limit.to_i, @max].min
  end

  def page
    @params[:page]&.to_i || 1
  end

  def offset
    (page - 1) * limit
  end
end
