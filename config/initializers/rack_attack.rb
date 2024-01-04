# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

THROTTLE_PUBLIC_ENDPOINTS = [
  {
    url:   '/api/v1/users/password_reset'.freeze,
    field: 'username',
  },
  {
    url:   '/api/v1/users/email_verify_send'.freeze,
    field: 'email',
  },
  {
    url:   '/api/v1/users/admin_password_auth'.freeze,
    field: 'username',
  },
].freeze

THROTTLE_PUBLIC_ENDPOINTS.each do |config|
  Rack::Attack.throttle("limit #{config[:url]} requests per #{config[:field]}", limit: 3, period: 1.minute.to_i) do |req|
    if req.path.start_with?(config[:url]) && req.post?
      # Normalize to protect against rate limit bypasses.
      req.params[config[:field]].to_s.downcase.gsub(%r{\s+}, '')
    end
  end
  Rack::Attack.throttle("limit #{config[:url]} requests per source IP address", limit: 3, period: 1.minute.to_i) do |req|
    if req.path.start_with?(config[:url]) && req.post?
      req.ip
    end
  end
end

#
# Throttle form submit requests
#
API_V1_FORM_SUBMIT_PATH = '/api/v1/form_submit'.freeze
form_limit_by_ip_per_hour_proc = proc { Setting.get('form_ticket_create_by_ip_per_hour') || 20 }
Rack::Attack.throttle('form submits per IP and hour', limit: form_limit_by_ip_per_hour_proc, period: 1.hour.to_i) do |req|
  if req.path.start_with?(API_V1_FORM_SUBMIT_PATH)
    req.ip
  end
end
form_limit_by_ip_per_day_proc = proc { Setting.get('form_ticket_create_by_ip_per_day') || 240 }
Rack::Attack.throttle('form submits per IP and day', limit: form_limit_by_ip_per_day_proc, period: 1.day.to_i) do |req|
  if req.path.start_with?(API_V1_FORM_SUBMIT_PATH)
    req.ip
  end
end
form_limit_per_day_proc = proc { Setting.get('form_ticket_create_per_day') || 5000 }
Rack::Attack.throttle('form submits per day', limit: form_limit_per_day_proc, period: 1.day.to_i) do |req|
  if req.path.start_with?(API_V1_FORM_SUBMIT_PATH)
    req.path
  end
end
