# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class AsyncOtrsImportJob < ApplicationJob
  def perform
    Import::OTRS.start_bg
  end
end
