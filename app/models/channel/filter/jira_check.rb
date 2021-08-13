# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Channel::Filter::JiraCheck < Channel::Filter::BaseExternalCheck
  MAIL_HEADER        = 'x-jira-fingerprint'.freeze
  SOURCE_ID_REGEX    = %r{\[JIRA\]\s\((\w+-\d+)\)}.freeze
  SOURCE_NAME_PREFIX = 'Jira'.freeze
end
