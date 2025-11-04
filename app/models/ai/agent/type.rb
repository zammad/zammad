# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Agent::Type
  include Mixin::RequiredSubPaths

  def self.available_types
    @available_types ||= descendants.sort_by(&:name)
  end

  def self.available_type_data
    available_types.map { |x| x.new.data }
  end

  attr_reader :enrichment_data

  def initialize(type_enrichment_data: {})
    @enrichment_data = type_enrichment_data
  end

  def data
    {
      id:,
      name:,
      description:,
      custom:,
      definition:,
      action_definition:,
      form_schema:,
      placeholder_field_names:,
    }
  end

  def name
    raise 'not implemented'
  end

  def description
    raise 'not implemented'
  end

  def custom
    false
  end

  def placeholder_field_names
    []
  end

  def object_attribute_dependencies
    return [] if placeholder_field_names.blank? || enrichment_data.blank?

    placeholder_field_names.filter_map { |name| enrichment_data[name].presence }
  end

  def form_schema
    []
  end

  def definition
    {
      role_description:,
      instruction_context:,
      instruction:,
      entity_context:,
      result_structure:,
    }
  end

  def action_definition
    raise 'not implemented'
  end

  def execution_definition
    transform_structure(definition)
  end

  def execution_action_definition
    transform_structure(action_definition)
  end

  def transform_structure(structure)
    # Convert hash to JSON string manually to avoid escaping ERB tags
    structure_json = structure.to_json.gsub('\\u003c%', '<%').gsub('%\\u003e', '%>')

    replaced_structure = replace_placeholders(structure_json)
    transformed_structure = render_structure(replaced_structure)

    JSON.parse(transformed_structure)
  end

  private

  def id
    self.class.name.demodulize
  end

  def instruction
    raise 'not implemented'
  end

  def role_description
    raise 'not implemented'
  end

  def instruction_context
    {}
  end

  def entity_context
    {
      object_attributes: ['title'],
      articles:          'all',
    }
  end

  def result_structure
    raise 'not implemented'
  end

  def replace_placeholders(structure_string)
    return structure_string if enrichment_data.blank?

    # Replace each placeholder that's defined in placeholder_names in early stage.
    placeholder_field_names.each do |placeholder_name|
      placeholder_pattern = "\#{placeholder.#{placeholder_name}}"
      replacement_value = enrichment_data[placeholder_name] || ''

      structure_string = structure_string.gsub(placeholder_pattern, replacement_value.to_s)
    end

    structure_string
  end

  def render_structure(structure)
    NotificationFactory::Renderer.new(
      objects:                { type_enrichment_data: enrichment_data_object },
      template:               structure,
      escape:                 false,
      url_encode:             false,
      ignore_missing_objects: true,
      trusted:                true,
    ).render(debug_errors: false)
  end

  def enrichment_data_object
    @enrichment_data_object ||= if enrichment_data.blank?
                                  nil
                                else
                                  Struct.new(*enrichment_data.keys.map(&:to_sym)).new(*enrichment_data)
                                end
  end
end
