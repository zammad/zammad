# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'delayed_job'

# Demote per-job RUNNING / COMPLETED lines from info to debug. These are
#   emitted for every single job and account for the bulk of DelayedJob log
#   pollution.
#
# Intercept `job_say` rather than lowering `Delayed::Worker.default_log_level`
#   globally — the latter would also demote fallback paths that rely on the
#   default level, e.g. `say "Error while reserving job: #{error}"` in
#   `reserve_job`. Explicit `'error'` FAILED lines also bypass this patch and
#   keep their original level.
#
# The pair of positive specs in `spec/jobs/application_job_spec.rb` (lines
#   appear at debug, disappear at info) will fail if DelayedJob ever renames
#   these messages.
module Delayed
  class Worker
    module ZammadJobLogLevelPatch
      def job_say(job, text, level = default_log_level)
        level = 'debug' if level == default_log_level && text.start_with?('RUNNING', 'COMPLETED')
        super
      end
    end

    prepend ZammadJobLogLevelPatch
  end
end
