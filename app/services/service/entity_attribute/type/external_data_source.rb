# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A value another system supplied, shown by its label. It cannot be set here: its values come from a search in that
#   system.
class Service::EntityAttribute::Type::ExternalDataSource < Service::EntityAttribute::Type
  handles 'autocompletion_ajax_external_data_source'

  def label(value)
    value['label'] || value['value']
  end
end
