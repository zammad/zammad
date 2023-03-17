# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Group
  module Assets
    extend ActiveSupport::Concern

    def filter_unauthorized_attributes(attributes)
      return super if UserInfo.assets.blank? || UserInfo.assets.agent?

      attributes = super
      attributes.slice('id', 'name', 'follow_up_possible', 'reopen_time_in_days', 'active')
    end
  end
end
