# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ModelClass < Sequencer::Unit::Common::Provider::Named

  uses :object

  MAP = {
    'Organization' => ::Organization,
    'User'         => ::User,
    'Team'         => ::Group,
    'Case'         => ::Ticket,
    'Post'         => ::Ticket::Article,
    'TimeEntry'    => ::Ticket::TimeAccounting,
  }.freeze

  private

  def model_class
    MAP[object]
  end
end
