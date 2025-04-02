# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Taskbar::Init::TicketStatsOrganization < Taskbar::Init::Backend
  def data(result)
    result[:ticket_stats_organization] = OrganizationPolicy::Scope
      .new(current_user, Organization.where(id: organization_ids))
      .resolve
      .each_with_object({}) do |elem, memo|
        elem.assets(result[:assets])
        memo[elem.id] = Ticket::Stats.new(current_user: current_user, organization_id: elem.id, assets: result[:assets]).list_stats.except(:assets)
      end
    result
  end
end
