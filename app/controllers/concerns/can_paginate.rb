# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module CanPaginate
  extend ActiveSupport::Concern

  def paginate_with(max: nil, default: nil)
    @paginate_max     = max
    @paginate_default = default
  end

  private

  def pagination
    @pagination ||= CanPaginate::Pagination.new(params, max: @paginate_max, default: @paginate_default)
  end
end
