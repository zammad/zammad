# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/email_parser/failed_email/delete_old.rb'
Tasks::Zammad::EmailParser::FailedEmail::DeleteOld.register_rake_task
