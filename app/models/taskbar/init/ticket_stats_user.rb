# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Taskbar::Init::TicketStatsUser < Taskbar::Init::Backend
  def data(result)
    result[:ticket_stats_user] = UserPolicy::Scope
      .new(current_user, User.where(id: user_ids))
      .resolve
      .each_with_object({}) do |elem, memo|
        elem.assets(result[:assets])
        memo[elem.id] = Ticket::Stats.new(current_user: current_user, user_id: elem.id, assets: result[:assets]).list_stats.except(:assets)
      end
    result
  end
end
