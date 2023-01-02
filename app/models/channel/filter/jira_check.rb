# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Channel::Filter::JiraCheck < Channel::Filter::BaseExternalCheck
  MAIL_HEADER        = 'x-jira-fingerprint'.freeze
  SOURCE_ID_REGEX    = %r{\[JIRA\]\s\((\w+-\d+)\)}
  SOURCE_NAME_PREFIX = 'Jira'.freeze
end
