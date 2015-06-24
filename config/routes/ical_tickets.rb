Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # ical ticket
  match api_path + '/ical/tickets',              to: 'ical_tickets#all',           via: :get
  match api_path + '/ical/tickets_new_open',     to: 'ical_tickets#new_open',      via: :get
  match api_path + '/ical/tickets_pending',      to: 'ical_tickets#pending',       via: :get
  match api_path + '/ical/tickets_escalation',   to: 'ical_tickets#escalation',    via: :get
end
