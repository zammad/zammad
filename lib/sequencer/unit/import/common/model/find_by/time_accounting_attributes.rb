# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Model::FindBy::TimeAccountingAttributes < Sequencer::Unit::Import::Common::Model::Lookup::CombinedAttributes

  private

  def attributes
    %i[ticket_id created_by_id created_at]
  end
end
