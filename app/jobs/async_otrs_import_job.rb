# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class AsyncOtrsImportJob < ApplicationJob
  def perform
    Import::OTRS.start_bg
  end
end
