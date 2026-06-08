# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module HasRecentCloses
  extend ActiveSupport::Concern

  included do
    after_destroy_commit :recent_close_destroy
  end

  def recent_close_destroy
    RecentClose.destroy_logs(self)
  end
end
