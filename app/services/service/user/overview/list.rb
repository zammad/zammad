# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::Overview::List < Service::Base
  attr_reader :user

  def initialize(user)
    super()

    @user = user
  end

  def execute
    scope = Ticket::OverviewsPolicy::Scope
      .new(user, Overview)
      .resolve
      .joins("LEFT JOIN user_overview_sortings ON user_overview_sortings.overview_id = overviews.id AND user_overview_sortings.user_id = #{user.id}")
      .select('overviews.*, user_overview_sortings.prio as user_prio, user_overview_sortings.id as user_prio_id')

    case ActiveRecord::Base.connection_db_config.configuration_hash[:adapter]
    when 'postgresql'
      scope.reorder('user_prio NULLS LAST, user_prio_id NULLS LAST, prio, id')
    when 'mysql2'
      scope.reorder(Arel.sql('ISNULL(user_prio), user_prio, ISNULL(user_prio_id), user_prio_id, prio, id'))
    end
  end
end
