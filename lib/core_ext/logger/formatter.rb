# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# This customization adds the id of the current Thread to all log lines.
# The #msg2str method will be extended, so that the "Rails.bracktrace_cleaner" can be used to clean the exceptions.
# It was introduced to make it more easy to follow the execution of tasks in the log in threaded processes.
#
# before:
# D, [2018-11-20T16:35:03.483547 #72102] DEBUG -- :    (0.5ms)  SELECT COUNT(*) FROM "delayed_jobs"
#
# after:
# D, [2018-11-20T16:35:03.483547 #72102-23423534] DEBUG -- :    (0.5ms)  SELECT COUNT(*) FROM "delayed_jobs"

class Logger
  class Formatter

    # original: Format    = "%s, [%s#%d] %5s -- %s: %s\n".freeze
    FORMAT_WITH_THREAD_ID = "%s, [%s#%d-%d] %5s -- %s: %s\n".freeze

    def call(severity, time, progname, msg)
      format(FORMAT_WITH_THREAD_ID, severity[0..0], format_datetime(time), Process.pid, Thread.current.object_id, severity, progname, msg2str(msg))
    end

    private

    def msg2str(msg)
      case msg
      when ::String
        msg
      when ::Exception
        # "#{ msg.message } (#{ msg.class })\n#{ msg.backtrace.join("\n") if msg.backtrace }"
        "#{msg.message} (#{msg.class})\n#{Rails.backtrace_cleaner.clean(msg.backtrace).join("\n") if msg.backtrace}"
      else
        msg.inspect
      end
    end
  end
end
