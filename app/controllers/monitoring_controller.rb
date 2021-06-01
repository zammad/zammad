# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
    issues = []
    actions = Set.new

    # channel check
    last_run_tolerance = Time.zone.now - 1.hour
    options_keys = %w[host user uid]
    Channel.where(active: true).each do |channel|

      # inbound channel
      if channel.status_in == 'error'
        message = "Channel: #{channel.area} in "
        options_keys.each do |key|
          next if channel.options[key].blank?

          message += "key:#{channel.options[key]};"
        end
        issues.push "#{message} #{channel.last_log_in}"
      end
      if channel.preferences && channel.preferences['last_fetch'] && channel.preferences['last_fetch'] < last_run_tolerance
        diff = Time.zone.now - channel.preferences['last_fetch']
        issues.push "#{message} channel is active but not fetched for #{helpers.time_ago_in_words(Time.zone.now - diff.seconds)}"
      end

      # outbound channel
      next if channel.status_out != 'error'

      message = "Channel: #{channel.area} out "
      options_keys.each do |key|
        next if channel.options[key].blank?

        message += "key:#{channel.options[key]};"
      end
      issues.push "#{message} #{channel.last_log_out}"
    end

    # unprocessable mail check
    directory = Rails.root.join('tmp/unprocessable_mail').to_s
    if File.exist?(directory)
      count = 0
      Dir.glob("#{directory}/*.eml") do |_entry|
        count += 1
      end
      if count.nonzero?
        issues.push "unprocessable mails: #{count}"
      end
    end

    # scheduler running check
    Scheduler.where('active = ? AND period > 300', true).where.not(last_run: nil).order(last_run: :asc, period: :asc).each do |scheduler|
      diff = Time.zone.now - (scheduler.last_run + scheduler.period.seconds)
      next if diff < 8.minutes

      issues.push "scheduler may not run (last execution of #{scheduler.method} #{helpers.time_ago_in_words(Time.zone.now - diff.seconds)} over) - please contact your system administrator"
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
      issues.push "#{count_failed_jobs} failing background jobs"
    end

    handler_attempts_map = {}
    failed_jobs.order(:created_at).limit(10).each do |job|

      job_name = if job.instance_of?(Delayed::Backend::ActiveRecord::Job) && job.payload_object.respond_to?(:job_data)
                   job.payload_object.job_data['job_class']
                 else
                   job.name
                 end

      handler_attempts_map[job_name] ||= {
        count:    0,
        attempts: 0,
      }

      handler_attempts_map[job_name][:count]    += 1
      handler_attempts_map[job_name][:attempts] += job.attempts
    end

    handler_attempts_map.sort.to_h.each_with_index do |(job_name, job_data), index|
      issues.push "Failed to run background job ##{index + 1} '#{job_name}' #{job_data[:count]} time(s) with #{job_data[:attempts]} attempt(s)."
    end

    # job count check
    total_jobs = Delayed::Job.where('created_at < ?', Time.zone.now - 15.minutes).count
    if total_jobs > 8000
      issues.push "#{total_jobs} background jobs in queue"
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
    import_backends.each do |backend| # rubocop:disable Style/CombinableLoops

      job = ImportJob.where(
        name:        backend,
        dry_run:     false,
        finished_at: nil,
      ).where('updated_at <= ?', 5.minutes.ago).limit(1).first

      next if job.blank?

      issues.push "Stuck import backend '#{backend}' detected. Last update: #{job.updated_at}"
    end

    # stuck data privacy tasks
    DataPrivacyTask.where.not(state: 'completed').where('updated_at <= ?', 30.minutes.ago).find_each do |task|
      issues.push "Stuck data privacy task (ID #{task.id}) detected. Last update: #{task.updated_at}"
    end

    token = Setting.get('monitoring_token')

    if issues.blank?
      result = {
        healthy: true,
        message: 'success',
        issues:  issues,
        token:   token,
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
    last_login = nil
    last_login_user = User.where.not(last_login: nil).order(last_login: :desc).limit(1).first
    if last_login_user
      last_login = last_login_user.last_login
    end

    status = {
      counts:          {},
      last_created_at: {},
      last_login:      last_login,
      agents:          User.with_permissions('ticket.agent').count,
    }

    map = {
      users:                     User,
      groups:                    Group,
      overviews:                 Overview,
      tickets:                   Ticket,
      ticket_articles:           Ticket::Article,
      text_modules:              TextModule,
      taskbars:                  Taskbar,
      object_manager_attributes: ObjectManager::Attribute,
      knowledge_base_categories: KnowledgeBase::Category,
      knowledge_base_answers:    KnowledgeBase::Answer,
    }
    map.each do |key, class_name|
      status[:counts][key] = class_name.count
      last = class_name.last
      status[:last_created_at][key] = last&.created_at
    end

    if ActiveRecord::Base.connection_config[:adapter] == 'postgresql'
      sql = 'SELECT SUM(CAST(coalesce(size, \'0\') AS INTEGER)) FROM stores'
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
    raise Exceptions::UnprocessableEntity, 'periode is missing!' if params[:periode].blank?

    scale = params[:periode][-1, 1]
    raise Exceptions::UnprocessableEntity, 'periode need to have s, m, h or d as last!' if !scale.match?(%r{^(s|m|h|d)$})

    periode = params[:periode][0, params[:periode].length - 1]
    raise Exceptions::UnprocessableEntity, 'periode need to be an integer!' if periode.to_i.zero?

    case scale
    when 's'
      created_at = Time.zone.now - periode.to_i.seconds
    when 'm'
      created_at = Time.zone.now - periode.to_i.minutes
    when 'h'
      created_at = Time.zone.now - periode.to_i.hours
    when 'd'
      created_at = Time.zone.now - periode.to_i.days
    end

    map = [
      { param: :max_critical, notice: 'critical', type: 'gt' },
      { param: :min_critical, notice: 'critical', type: 'lt' },
      { param: :max_warning, notice: 'warning', type: 'gt' },
      { param: :min_warning, notice: 'warning', type: 'lt' },
    ]
    result = {}
    state_param = false
    map.each do |row|
      next if params[row[:param]].blank?
      raise Exceptions::UnprocessableEntity, "#{row[:param]} need to be an integer!" if params[row[:param]].to_i.zero?

      state_param = true

      count = Ticket.where('created_at >= ?', created_at).count

      if row[:type] == 'gt'
        if count > params[row[:param]].to_i
          result = {
            state:   row[:notice],
            message: "The limit of #{params[row[:param]]} was exceeded with #{count} in the last #{params[:periode]}",
            count:   count,
          }
          break
        end
        next
      end
      next if count > params[row[:param]].to_i

      result = {
        state:   row[:notice],
        message: "The minimum of #{params[row[:param]]} was undercut by #{count} in the last #{params[:periode]}",
        count:   count,
      }
      break
    end

    if result.blank?
      result = {
        state: 'ok',
        count: Ticket.where('created_at >= ?', created_at).count,
      }
    end

    if state_param == false
      result.delete(:state)
    end

    render json: result
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
