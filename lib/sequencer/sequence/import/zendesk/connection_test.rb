# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Zendesk::ConnectionTest < Sequencer::Sequence::Base

  def self.expecting
    [:connected]
  end

  def self.sequence
    [
      'Zendesk::Client',
      'Zendesk::Connected',
    ]
  end
end
