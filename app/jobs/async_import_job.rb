# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class AsyncImportJob < ApplicationJob
  def perform(import_job)
    import_job.start
  end
end
