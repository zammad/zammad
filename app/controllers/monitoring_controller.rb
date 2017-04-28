# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class MonitoringController < ApplicationController
  prepend_before_action -> { authentication_check(permission: 'admin.monitoring') }, except: [:health_check, :status]
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
    token_or_permission_check

    issues = []

    # channel check
    last_run_tolerance = Time.zone.now - 1.hour
    Channel.where(active: true).each { |channel|

      # inbound channel
      if channel.status_in == 'error'
        message = "Channel: #{channel.area} in "
        %w(host user uid).each { |key|
          next if !channel.options[key] || channel.options[key].empty?
          message += "key:#{channel.options[key]};"
        }
        issues.push "#{message} #{channel.last_log_in}"
      end
      if channel.preferences && channel.preferences['last_fetch'] && channel.preferences['last_fetch'] < last_run_tolerance
        issues.push "#{message} channel is active but not fetched for 1 hour"
      end

      # outbound channel
      next if channel.status_out != 'error'
      message = "Channel: #{channel.area} out "
      %w(host user uid).each { |key|
        next if !channel.options[key] || channel.options[key].empty?
        message += "key:#{channel.options[key]};"
      }
      issues.push "#{message} #{channel.last_log_out}"
    }

    # unprocessable mail check
    directory = "#{Rails.root}/tmp/unprocessable_mail"
    if File.exist?(directory)
      count = 0
      Dir.glob("#{directory}/*.eml") { |_entry|
        count += 1
      }
      if count.nonzero?
        issues.push "unprocessable mails: #{count}"
      end
    end

    # scheduler check
    Scheduler.where(active: true).where.not(last_run: nil).each { |scheduler|
      next if scheduler.period <= 300
      next if scheduler.last_run + scheduler.period.seconds > Time.zone.now - 5.minutes
      issues.push 'scheduler not running'
      break
    }
    if Scheduler.where(active: true, last_run: nil).count == Scheduler.where(active: true).count
      issues.push 'scheduler not running'
    end

    token = Setting.get('monitoring_token')

    if issues.empty?
      result = {
        healthy: true,
        message: 'success',
        token: token,
      }
      render json: result
      return
    end

    result = {
      healthy: false,
      message: issues.join(';'),
      issues: issues,
      token: token,
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
    token_or_permission_check

    last_login = nil
    last_login_user = User.where('last_login IS NOT NULL').order(last_login: :desc).limit(1).first
    if last_login_user
      last_login = last_login_user.last_login
    end

    status = {
      counts: {},
      last_created_at: {},
      last_login: last_login,
      agents: User.with_permissions('ticket.agent').count,
    }

    map = {
      users: User,
      groups: Group,
      overviews: Overview,
      tickets: Ticket,
      ticket_articles: Ticket::Article,
    }
    map.each { |key, class_name|
      status[:counts][key] = class_name.count
      last = class_name.last
      status[:last_created_at][key] = if last
                                        last.created_at
                                      end
    }

    render json: status
  end

  def token
    access_check
    token = SecureRandom.urlsafe_base64(40)
    Setting.set('monitoring_token', token)

    result = {
      token: token,
    }
    render json: result, status: :created
  end

  private

  def token_or_permission_check
    user = authentication_check_only(permission: 'admin.monitoring')
    return if user
    return if Setting.get('monitoring_token') == params[:token]
    raise Exceptions::NotAuthorized
  end

  def access_check
    return if Permission.find_by(name: 'admin.monitoring', active: true)
    raise Exceptions::NotAuthorized
  end

end
