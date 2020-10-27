class AsyncImportJob < ApplicationJob
  def perform(import_job)
    import_job.start
  end
end
