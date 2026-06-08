# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::System::Import::Run < Service::Base
  def initialize
    configured!
  end

  def execute
    Setting.set('import_mode', true)
    source = Setting.get('import_backend')

    case source
    when 'otrs'
      execute_otrs_import
    else
      execute_import(source)
    end
  end

  private

  def execute_import(source)
    job_name = "Import::#{source.camelize}"

    ImportJob.create!(name: job_name, start_after_creation: true)
  end

  def execute_otrs_import
    ApplicationModel.current_transaction.after_commit do
      AsyncOtrsImportJob.perform_later
    end
  end

  def configured!
    raise Service::System::CheckSetup::SystemSetupError, __('This system has already been configured.') if Service::System::CheckSetup.done?
    raise ExecuteError if Setting.get('import_backend').empty?
  end

  class ExecuteError < StandardError
    def initialize(message = __('Please configure import source before running.'))
      super
    end
  end
end
