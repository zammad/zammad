# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Users < Sequencer::Unit::Import::Zendesk::SubSequence::Object
  include ::Sequencer::Unit::Import::Zendesk::Mixin::IncrementalExport

  uses :organization_map, :group_map, :user_group_map, :field_map

  private

  def default_params
    super.merge(
      organization_map: organization_map,
      group_map:        group_map,
      user_group_map:   user_group_map,
      field_map:        field_map,
    )
  end
end
