# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class RackAttackSetup
  class FormEndpoint
    API_V1_FORM_SUBMIT_PATH = '/api/v1/form_submit'.freeze
    THROTTLES               = [
      {
        name:        'form submits per IP and hour',
        setting:     'form_ticket_create_by_ip_per_hour',
        default:     20,
        period:      1.hour,
        return_proc: proc(&:ip),
      },
      {
        name:        'form submits per IP and day',
        setting:     'form_ticket_create_by_ip_per_day',
        default:     240,
        period:      1.day,
        return_proc: proc(&:ip),
      },
      {
        name:        'form submits per day',
        setting:     'form_ticket_create_per_day',
        default:     5000,
        period:      1.day,
        return_proc: proc { API_V1_FORM_SUBMIT_PATH },
      },
    ].freeze

    def self.setup_single_throttle(name:, setting:, default:, period:, return_proc:)
      limit_proc = proc { Setting.get(setting) || default }
      Rack::Attack.throttle(name, limit: limit_proc, period: period.to_i) do |req|
        next if !RackAttackSetup.path_matches?(req.path, API_V1_FORM_SUBMIT_PATH)

        return_proc.call(req)
      end
    end

    def self.setup
      THROTTLES.each do |config|
        setup_single_throttle(**config)
      end
    end
  end
end
