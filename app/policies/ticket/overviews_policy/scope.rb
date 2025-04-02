# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Ticket::OverviewsPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve(ignore_user_conditions: false)
      return scope.none if !user.permissions?(%w[ticket.customer ticket.agent])

      scope = base_query

      if !ignore_user_conditions
        scope = scope.where(organization_shared: false) if !user.shared_organizations?
        scope = scope.where.not(out_of_office: true) if !user.someones_out_of_office_replacement?
      end

      scope
    end

    private

    def base_query
      scope.distinct
              .joins(roles: :users)
              .where(active: true)
              .where(roles: { active: true })
              .where(users: { id: user.id, active: true })
              .left_joins(:users)
              .where(overviews_users: { user_id: [nil, user.id] })
    end
  end
end
