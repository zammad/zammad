# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/email_parser/failed_email/import.rb'
Tasks::Zammad::EmailParser::FailedEmail::Import.register_rake_task
