# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class MonitoringController < ApplicationController
  prepend_before_action { authorize! }
  prepend_before_action -> { authentication_check }, except: %i[health_check status amount_check]
  prepend_before_action -> { authentication_check_only }, only: %i[health_check status amount_check]

  skip_before_action :verify_csrf_token

=begin

Resource:
GET /api/v1/monitoring/health_check?token=XXX

Response:
{
  "healthy": true,
  "message": "success",
}

{
  "healthy": false,
  "message": "authentication of XXX failed; issue #2",
  "issues": ["authentication of XXX failed", "issue #2"],
}

Test:
curl http://localhost/api/v1/monitoring/health_check?token=XXX

=end

  def health_check
    health_status = MonitoringHelper::HealthChecker.new
    health_status.check_health

    token = Setting.get('monitoring_token')

    result = {
      healthy: health_status.healthy?,
      message: health_status.message,
      issues:  health_status.response.issues,
      actions: health_status.response.actions,
      token:   token,
    }
    render json: result
  end

=begin

Resource:
GET /api/v1/monitoring/status?token=XXX

Response:
{
  "agents": 8123,
  "last_login": "2016-11-21T14:14:14Z",
  "counts": {
    "users": 12313,
    "tickets": 23123,
    "ticket_articles": 131451,
  },
  "last_created_at": {
    "users": "2016-11-21T14:14:14Z",
    "tickets": "2016-11-21T14:14:14Z",
    "ticket_articles": "2016-11-21T14:14:14Z",
  },
}

Test:
curl http://localhost/api/v1/monitoring/status?token=XXX

=end

  def status
    render json: MonitoringHelper::Status.new.fetch_status
  end

=begin

get counts about created ticket in certain time slot. s, m, h and d possible.

Resource:

GET /api/v1/monitoring/amount_check?token=XXX&max_warning=2000&max_critical=3000&periode=1h

GET /api/v1/monitoring/amount_check?token=XXX&min_warning=2000&min_critical=3000&periode=1h

GET /api/v1/monitoring/amount_check?token=XXX&periode=1h

Response:
{
  "state": "ok",
  "message": "",
  "count": 123,
}

{
  "state": "warning",
  "message": "limit of 2000 tickets in 1h reached",
  "count": 123,
}

{
  "state": "critical",
  "message": "limit of 3000 tickets in 1h reached",
  "count": 123,
}

Test:
curl http://localhost/api/v1/monitoring/amount_check?token=XXX&max_warning=2000&max_critical=3000&periode=1h

curl http://localhost/api/v1/monitoring/amount_check?token=XXX&min_warning=2000&min_critical=3000&periode=1h

curl http://localhost/api/v1/monitoring/amount_check?token=XXX&periode=1h

=end

  def amount_check
    render json: MonitoringHelper::AmountCheck.new(params).check_amount
  end

  def token
    token = SecureRandom.urlsafe_base64(40)
    Setting.set('monitoring_token', token)

    result = {
      token: token,
    }
    render json: result, status: :created
  end

  def restart_failed_jobs
    Scheduler.restart_failed_jobs

    render json: {}, status: :ok
  end
end
