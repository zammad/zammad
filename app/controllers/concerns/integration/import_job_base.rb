module Integration::ImportJobBase
  extend ActiveSupport::Concern

  def job_try_index
    job_index(
      dry_run:       true,
      take_finished: params[:finished] == 'true'
    )
  end

  def job_try_create
    ImportJob.dry_run(name: import_backend_namespace, payload: payload_dry_run)
    render json: {
      result: 'ok',
    }
  end

  def job_start_index
    job_index(dry_run: false)
  end

  def job_start_create
    if !ImportJob.exists?(name: import_backend_namespace, finished_at: nil)
      job = ImportJob.create(name: import_backend_namespace, payload: payload_import)
      job.delay.start
    end
    render json: {
      result: 'ok',
    }
  end

  def payload_dry_run
    params
  end

  def payload_import
    import_setting
  end

  private

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

  def import_setting
    Setting.get(import_setting_name)
  end

  def import_setting_name
    "#{import_backend_name.downcase}_config"
  end

  def import_backend_namespace
    "Import::#{import_backend_name}"
  end

  def import_backend_name
    self.class.name.split('::').last.sub('Controller', '')
  end

  def job_index(dry_run:, take_finished: true)
    job = ImportJob.find_by(
      name:        import_backend_namespace,
      dry_run:     dry_run,
      finished_at: nil
    )
    if !job && take_finished
      job = ImportJob.where(
        name:    import_backend_namespace,
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
