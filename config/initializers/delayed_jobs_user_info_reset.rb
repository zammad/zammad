# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'delayed_job'

class ResetUserInfoPlugin < Delayed::Plugin

  callbacks do |lifecycle|
    lifecycle.before(:invoke_job) do |*_args|

      Rails.logger.debug { 'Resetting UserInfo before Job execution' }

      # Worker threads are reused and not every call site restores the user context it sets, so a
      # job could otherwise start with a leftover user from an unrelated job, and ApplicationJob
      # decides on that user whether the job runs as system. The system context itself is not
      # cleared here and does not need to be: UserInfo.with_system_context is its only writer
      # and restores the previous value in an ensure.
      UserInfo.reset
    end
  end
end

Delayed::Worker.plugins << ResetUserInfoPlugin
