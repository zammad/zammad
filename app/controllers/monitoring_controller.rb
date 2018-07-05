# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class MonitoringController < ApplicationController
  prepend_before_action -> { authentication_check(permission: 'admin.monitoring') }, except: %i[health_check status]
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
    actions = Set.new

    # channel check
    last_run_tolerance = Time.zone.now - 1.hour
    Channel.where(active: true).each do |channel|

      # inbound channel
      if channel.status_in == 'error'
        message = "Channel: #{channel.area} in "
        %w[host user uid].each do |key|
          next if channel.options[key].blank?
          message += "key:#{channel.options[key]};"
        end
        issues.push "#{message} #{channel.last_log_in}"
      end
      if channel.preferences && channel.preferences['last_fetch'] && channel.preferences['last_fetch'] < last_run_tolerance
        issues.push "#{message} channel is active but not fetched for 1 hour"
      end

      # outbound channel
      next if channel.status_out != 'error'
      message = "Channel: #{channel.area} out "
      %w[host user uid].each do |key|
        next if channel.options[key].blank?
        message += "key:#{channel.options[key]};"
      end
      issues.push "#{message} #{channel.last_log_out}"
    end

    # unprocessable mail check
    directory = Rails.root.join('tmp', 'unprocessable_mail').to_s
    if File.exist?(directory)
      count = 0
      Dir.glob("#{directory}/*.eml") do |_entry|
        count += 1
      end
      if count.nonzero?
        issues.push "unprocessable mails: #{count}"
      end
    end

    # scheduler check
    Scheduler.where(active: true).where.not(last_run: nil).each do |scheduler|
      next if scheduler.period <= 300
      next if scheduler.last_run + scheduler.period.seconds > Time.zone.now - 5.minutes
      issues.push 'scheduler not running'
      break
    end
    if Scheduler.where(active: true, last_run: nil).count == Scheduler.where(active: true).count
      issues.push 'scheduler not running'
    end

    Scheduler.failed_jobs.each do |job|
      issues.push "Failed to run scheduled job '#{job.name}'. Cause: #{job.error_message}"
      actions.add(:restart_failed_jobs)
    end

    # failed jobs check
    failed_jobs       = Delayed::Job.where('attempts > 0')
    count_failed_jobs = failed_jobs.count

    if count_failed_jobs > 10
      issues.push "#{count_failed_jobs} failing background jobs."
    end

    listed_failed_jobs = failed_jobs.select(:handler, :attempts).limit(10)
    sorted_failed_jobs = listed_failed_jobs.group_by(&:name).sort_by { |_handler, entries| entries.length }.reverse.to_h
    sorted_failed_jobs.each_with_index do |(name, jobs), index|

      attempts = jobs.map(&:attempts).sum

      issues.push "Failed to run background job ##{index += 1} '#{name}' #{jobs.count} time(s) with #{attempts} attempt(s)."
    end

    # import jobs
    import_backends = ImportJob.backends

    # failed import jobs
    import_backends.each do |backend|

      job = ImportJob.where(
        name:    backend,
        dry_run: false,
      ).where('finished_at >= ?', 5.minutes.ago).limit(1).first

      next if job.blank?
      next if !job.result.is_a?(Hash)

      error_message = job.result[:error]
      next if error_message.blank?

      issues.push "Failed to run import backend '#{backend}'. Cause: #{error_message}"
    end

    # stuck import jobs
    import_backends.each do |backend|

      job = ImportJob.where(
        name:        backend,
        dry_run:     false,
        finished_at: nil,
      ).where('updated_at <= ?', 5.minutes.ago).limit(1).first

      next if job.blank?

      issues.push "Stuck import backend '#{backend}' detected. Last update: #{job.updated_at}"
    end

    token = Setting.get('monitoring_token')

    if issues.blank?
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
      issues:  issues,
      actions: actions,
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
    map.each do |key, class_name|
      status[:counts][key] = class_name.count
      last = class_name.last
      status[:last_created_at][key] = last&.created_at
    end

    if ActiveRecord::Base.connection_config[:adapter] == 'postgresql'
      sql = 'SELECT SUM(CAST(coalesce(size, \'0\') AS INTEGER)) FROM stores WHERE id IN (SELECT DISTINCT(store_file_id) FROM stores)'
      records_array = ActiveRecord::Base.connection.exec_query(sql)
      if records_array[0] && records_array[0]['sum']
        sum = records_array[0]['sum']
        status[:storage] = {
          kB: sum / 1024,
          MB: sum / 1024 / 1024,
          GB: sum / 1024 / 1024 / 1024,
        }
      end
    end
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

  def restart_failed_jobs
    access_check

    Scheduler.restart_failed_jobs

    render json: {}, status: :ok
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
