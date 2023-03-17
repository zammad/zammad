# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::TicketField::SanitizedName < Sequencer::Unit::Import::Common::ObjectAttribute::SanitizedName

  uses :resource

  private

  def unsanitized_name
    # Model ID
    # Model IDs
    # Model / Name
    # Model Name
    # Model Name?
    # Model::Name
    resource.title
  end
end
