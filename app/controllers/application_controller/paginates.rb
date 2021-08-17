# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationController::Paginates
  extend ActiveSupport::Concern

  def paginate_with(max: nil, default: nil)
    @paginate_max     = max
    @paginate_default = default
  end

  private

  def pagination
    @pagination ||= ::ApplicationController::Paginates::Pagination.new(params, max: @paginate_max, default: @paginate_default)
  end
end
