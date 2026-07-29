# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module HasRecentViews
  extend ActiveSupport::Concern

  included do
    before_destroy :recent_view_destroy
  end

  def recent_view_destroy
    RecentView.log_destroy(self)
  end
end
