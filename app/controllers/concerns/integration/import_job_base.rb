# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Integration::ImportJobBase
  extend ActiveSupport::Concern

  def job_try_index
    job_index(
      dry_run:       true,
      take_finished: params[:finished] == 'true'
    )
  end

  def job_try_create
    ImportJob.dry_run(name: backend, payload: payload_dry_run)
    render json: {
      result: 'ok',
    }
  end

  def job_start_index
    job_index(dry_run: false)
  end

  def job_start_create
    if !ImportJob.exists?(name: backend, finished_at: nil)
      job = ImportJob.create(name: backend)
      AsyncImportJob.perform_later(job)
    end
    render json: {
      result: 'ok',
    }
  end

  def payload_dry_run
    clean_payload(params.permit!.to_h)
  end

  private

  def clean_payload(payload)
    payload.except(:wizardData, :action, :controller)
  end

  def answer_with
    result = yield
    render json: result.merge(result: 'ok')
  rescue => e
    logger.error(e)
    render json: {
      result:  'failed',
      message: e.message,
    }
  end

  def backend
    "Import::#{controller_name.classify}"
  end

  def job_index(dry_run:, take_finished: true)
    job = ImportJob.find_by(
      name:        backend,
      dry_run:     dry_run,
      finished_at: nil
    )
    if !job && take_finished
      job = ImportJob.where(
        name:    backend,
        dry_run: dry_run
      ).order(created_at: :desc).limit(1).first
    end

    if job
      model_show_render_item(job)
    else
      render json: {}
    end
  end

end
