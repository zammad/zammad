# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/agent_dashboard/sla_at_risk', to: 'agent_dashboard#sla_at_risk', via: :get
  match api_path + '/agent_dashboard/workload',    to: 'agent_dashboard#workload',    via: :get
end
