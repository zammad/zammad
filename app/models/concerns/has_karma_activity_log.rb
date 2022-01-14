# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module HasKarmaActivityLog
  extend ActiveSupport::Concern

  included do
    before_destroy :karma_activity_log_destroy
  end

=begin

delete object online notification list, will be executed automatically

  model = Model.find(123)
  model.karma_activity_log_destroy

=end

  def karma_activity_log_destroy
    Karma::ActivityLog.remove(self.class.to_s, id)
    true
  end
end
