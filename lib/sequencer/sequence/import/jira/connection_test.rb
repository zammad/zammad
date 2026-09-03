# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Jira::ConnectionTest < Sequencer::Sequence::Base

  def self.expecting
    [:connected]
  end

  def self.sequence
    [
      'Jira::Connected',
    ]
  end
end
