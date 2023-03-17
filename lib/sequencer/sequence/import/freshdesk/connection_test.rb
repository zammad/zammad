# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Freshdesk::ConnectionTest < Sequencer::Sequence::Base

  def self.expecting
    [:connected]
  end

  def self.sequence
    [
      'Freshdesk::Connected',
    ]
  end
end
