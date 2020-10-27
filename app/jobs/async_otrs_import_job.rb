class AsyncOtrsImportJob < ApplicationJob
  def perform
    Import::OTRS.start_bg
  end
end
