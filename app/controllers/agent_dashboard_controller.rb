# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Lightweight read-only endpoints powering the faithful Agent Console
# dashboard. Each action returns JSON tuned to one widget so the frontend
# doesn't have to over-fetch from the existing tickets endpoint.
#
# See: docs/plans/agent-console-faithful.md
# Wireframe:  docs/ui-references/agent-console/agent-screens.jsx
class AgentDashboardController < ApplicationController
  prepend_before_action :authenticate_and_authorize_agent!

  # GET /api/v1/agent_dashboard/sla_at_risk
  #
  # Tickets the current agent can see with the soonest escalation_at,
  # excluding tickets that have already breached (escalation_at <= now)
  # to keep the widget actionable.
  def sla_at_risk
    horizon_hours = params[:within_hours].presence&.to_i || 24
    horizon_hours = horizon_hours.clamp(1, 168)

    scope = TicketPolicy::ReadScope.new(current_user).resolve
    tickets = scope
      .where.not(escalation_at: nil)
      .where(escalation_at: Time.zone.now..(horizon_hours.hours.from_now))
      .where(state_id: open_state_ids)
      .reorder(escalation_at: :asc)
      .limit(10)
      .includes(:customer, :group, :state, :priority)

    render json: tickets.map { |t| present_sla_ticket(t) }, status: :ok
  end

  # GET /api/v1/agent_dashboard/workload
  #
  # Open ticket count per active agent. Used by the wireframe's
  # "Team workload" widget.
  def workload
    state_ids = open_state_ids
    counts = Ticket
      .where(state_id: state_ids)
      .where.not(owner_id: 1) # exclude the "-" placeholder owner
      .group(:owner_id)
      .count

    agents = User
      .joins(:roles)
      .where(active: true, roles: { name: 'Agent' })
      .or(User.joins(:roles).where(active: true, roles: { name: 'Admin' }))
      .distinct

    payload = agents.map do |u|
      { agent_id: u.id, name: u.fullname.presence || u.email, open_count: counts[u.id].to_i }
    end.sort_by { |row| -row[:open_count] }

    render json: payload, status: :ok
  end

  private

  def authenticate_and_authorize_agent!
    authentication_check
    return if current_user&.permissions?('ticket.agent')

    raise Exceptions::Forbidden, __('Access denied.')
  end

  def open_state_ids
    Ticket::State
      .by_category_ids(:work_on)
      .presence || Ticket::State.where(name: %w[new open]).pluck(:id)
  end

  def present_sla_ticket(ticket)
    {
      id:            ticket.id,
      number:        ticket.number,
      title:         ticket.title,
      escalation_at: ticket.escalation_at,
      state:         ticket.state&.name,
      priority:      ticket.priority&.name,
      group:         ticket.group&.name,
      customer_name: ticket.customer&.fullname.presence || ticket.customer&.email,
    }
  end
end
