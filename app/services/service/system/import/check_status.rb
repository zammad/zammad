# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::System::Import::CheckStatus < Service::Base

  attr_reader :source

  def initialize
    super

    @source = Setting.get('import_backend')

    running!
  end

  def execute
    # Captain, oh my captain! Again, I'm so sorry, but we need to do it.
    return execute_otrs_check if @source == 'otrs'

    job_name = "Import::#{@source.camelize}"
    job = ImportJob.find_by(name: job_name)

    Setting.reload if job.finished_at.present?

    job
  end

  private

  def execute_otrs_check
    result = Import::OTRS.status_bg

    Setting.reload if result[:result] == 'import_done'

    result
  end

  def running!
    setup = Service::System::CheckSetup.new
    setup.execute

    return if setup.status == 'in_progress' && setup.type == 'import'
    return if setup.status == 'done' && @source.present?

    raise Service::System::Import::Run::ExecuteError, __('No import in progress.')
  end
end
