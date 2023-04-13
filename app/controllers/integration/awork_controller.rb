class Integration::AworkController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  def verify
    awork = ::Awork.new(params[:endpoint], params[:api_token])

    awork.verify

    render json: {
      result: 'ok',
    }
  rescue => e
    logger.error e

    render json: {
      result:  'failed',
      message: e.message,
    }
  end

  def update
    link_tasks(params[:linked_tasks])

    render json: {
      result:   'ok',
    }
  rescue => e
    logger.error e

    render json: {
      result:  'failed',
      message: e.message,
    }
  end

  def create
    config = Setting.get('awork_config')

    awork = ::Awork.new(config['endpoint'], config['api_token'])

    task = awork.create(params[:create_task])

    link_tasks(params[:linked_tasks].add(task.result['id']))

    render json: {
      result:   'ok',
    }
  rescue => e
    logger.error e

    render json: {
      result:  'failed',
      message: e.message,
    }
  end

  def linked_tasks
    config = Setting.get('awork_config')

    awork = ::Awork.new(config['endpoint'], config['api_token'])

    ticket = Ticket.find(params[:ticket_id])
    ids = ticket.preferences[:awork][:task_ids] || []

    render json: {
      result:   'ok',
      response: awork.linked_tasks(ids),
    }
  rescue => e
    logger.error e

    render json: {
      result:  'failed',
      message: e.message,
    }
  end

  def projects
    config = Setting.get('awork_config')

    awork = ::Awork.new(config['endpoint'], config['api_token'])

    render json: {
      result:   'ok',
      response: awork.projects,
    }
  rescue => e
    logger.error e

    render json: {
      result:  'failed',
      message: e.message,
    }
  end

  def tasks_by_project
    config = Setting.get('awork_config')

    awork = ::Awork.new(config['endpoint'], config['api_token'])

    render json: {
      result:   'ok',
      response: awork.tasks_by_project(params[:project_id]),
    }
  rescue => e
    logger.error e

    render json: {
      result:  'failed',
      message: e.message,
    }
  end

  private

  def link_tasks(task)
    ticket = Ticket.find(params[:ticket_id])
    ticket.with_lock do
      authorize!(ticket, :show?)
      ticket.preferences[:awork] ||= {}
      ticket.preferences[:awork][:task_ids] = Array(task).uniq
      ticket.save!
    end
  end

end
