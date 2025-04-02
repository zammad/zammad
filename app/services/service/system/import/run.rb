# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::System::Import::Run < Service::Base
  def initialize
    super

    configured!
  end

  def execute
    Setting.set('import_mode', true)
    source = Setting.get('import_backend')

    # Captain, oh my captain! I hate to do this, but we need to do it.
    return execute_otrs_import if source == 'otrs'

    job_name = "Import::#{source.camelize}"
    job = ImportJob.create(name: job_name)
    AsyncImportJob.perform_later(job)
  end

  private

  def execute_otrs_import
    AsyncOtrsImportJob.perform_later
  end

  def configured!
    raise ExecuteError if Setting.get('import_backend').empty?
  end

  class ExecuteError < StandardError
    def initialize(message = __('Please configure import source before running.'))
      super
    end
  end
end
