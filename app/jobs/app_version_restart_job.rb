# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class AppVersionRestartJob < ApplicationJob
  def perform(cmd)
    Rails.logger.info "executing CMD: #{cmd}"
    ::Kernel.system(cmd)
    Rails.logger.info "executed CMD: #{cmd}"
  end
end
