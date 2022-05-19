# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Ticket::OverviewsPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.permissions?('ticket.customer')
        customer_scope
      elsif user.permissions?('ticket.agent')
        agent_scope
      else
        empty_scope
      end
    end

    private

    def customer_scope
      if user.shared_organizations?
        base_query
      else
        base_query.where(organization_shared: false)
      end
    end

    def agent_scope
      if user_is_someones_out_of_office_replacement?
        base_query
      else
        base_query.where.not(out_of_office: true)
      end
    end

    def empty_scope
      scope.where(id: nil)
    end

    def base_query
      scope.joins(roles: :users)
              .where(active: true)
              .where(roles: { active: true })
              .where(users: { id: user.id, active: true })
              .left_joins(:users)
              .where(overviews_users: { user_id: [nil, user.id] })
    end

    def user_is_someones_out_of_office_replacement?
      User.where(out_of_office: true)
          .where('out_of_office_start_at <= ?', Time.zone.today)
          .where('out_of_office_end_at >= ?', Time.zone.today)
          .where(out_of_office_replacement_id: user.id)
          .exists?(active: true)
    end
  end
end
