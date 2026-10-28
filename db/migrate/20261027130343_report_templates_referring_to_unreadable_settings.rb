# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Names the admin-written templates, and the setting values, that refer to a setting templates no
# longer resolve, so an admin can replace the placeholder before a recipient sees it rendered as a
# missing object or dropped from a value.
class ReportTemplatesReferringToUnreadableSettings < ActiveRecord::Migration[8.1]
  # A template is parsed as the renderer parses it, a setting value as Setting interpolates it.
  COMPILED_REFERENCE = %r{<%= c "([^"]+)"}
  VALUE_REFERENCE    = %r{\#\{config\.(.+?)\}}

  TEMPLATE_ATTRIBUTES = {
    'Trigger'                  => :perform,
    'Job'                      => :perform,
    'Macro'                    => :perform,
    'TextModule'               => :content,
    'Signature'                => :body,
    'AI::TextTool'             => :instruction,
    'AI::Agent'                => :type_enrichment_data,
    'ObjectManager::Attribute' => :data_option, # link templates and external data source search URLs
    'Setting'                  => :state_current,
  }.freeze

  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    TEMPLATE_ATTRIBUTES.each do |model_name, attribute|
      model_name.constantize.find_each do |record|
        names = referenced_settings(record, record[attribute]).reject { |name| resolves?(record, name) }
        next if names.empty?

        Rails.logger.warn "Templates referring to settings: #{model_name} '#{display_name(record)}' (id #{record.id}) #{consequence(record, names)}"
      end
    end
  end

  private

  def referenced_settings(record, value)
    strings(value)
      .flat_map { |text| references_in(record, text) }
      .uniq
  end

  def references_in(record, text)
    return text.scan(VALUE_REFERENCE).flatten if record.is_a?(Setting)

    NotificationFactory::Template.new(text, false, false).to_s.scan(COMPILED_REFERENCE).flatten
  end

  def resolves?(record, name)
    return true if !Setting.known?(name)
    return Setting.reference_kept?(record.name, name) if record.is_a?(Setting)

    Setting.template_readable?(name)
  end

  # An attribute name is unique per object only.
  def display_name(record)
    return "#{record.object_lookup.name}##{record.name}" if record.is_a?(ObjectManager::Attribute)

    record.name
  end

  def consequence(record, names)
    case record
    when Setting
      "refers to settings its value no longer takes in: #{names.join(', ')}. Replace the placeholders, they are dropped from the value."
    when AI::Agent
      "refers to settings templates no longer resolve: #{names.join(', ')}. Replace the placeholders, they stay unresolved in the prompt."
    else
      "refers to settings templates no longer resolve: #{names.join(', ')}. Replace the placeholders, they render as missing objects."
    end
  end

  def strings(value)
    case value
    when Hash   then value.values.flat_map { |nested| strings(nested) }
    when Array  then value.flat_map { |nested| strings(nested) }
    when String then [value]
    else []
    end
  end
end
