# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::ApplyValue::Tags < FormUpdater::ApplyValue::Base

  def can_handle_field?(field:, field_attribute:)
    field == 'tags'
  end

  def skip_dirty_field?(field:)
    false
  end

  def map_value(field:, config:)
    selected_tags = data['tags'].presence || []
    template_tags = config['value'].split(%r{,\s*}).presence || []

    tag_values = if config['operator'] == 'add'
                   if meta[:dirty_fields]&.include?('tags')
                     selected_tags | template_tags
                   else
                     template_tags
                   end
                 elsif config['operator'] == 'remove'
                   selected_tags - template_tags
                 else
                   template_tags
                 end

    result['tags'][:value] = tag_values
    result['tags'][:options] = tag_values.map { |tag| { value: tag, label: tag } }
  end
end
