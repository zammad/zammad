# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Agent::Type
  include Mixin::RequiredSubPaths

  # Simple value object for inline precondition checks defined directly in a type.
  # `condition` is a callable evaluated lazily by `passed?`, so checks are only
  # executed when needed and short-circuit evaluation in the service is possible.
  # For checks reused across multiple types, extract to a dedicated service class.
  PreconditionCheck = Data.define(:name, :condition) do
    def passed? = condition.call
  end

  def self.available_types
    @available_types ||= descendants.sort_by(&:name)
  end

  def self.available_type_data
    available_types.map { |x| x.new.data }
  end

  def initialize(type_enrichment_data: {})
    @user_type_enrichment_data = type_enrichment_data.stringify_keys
  end

  # Per-instance enrichment data used for prompt rendering. Layers:
  #   `base_type_enrichment_data` (runtime-only, hidden from the form),
  #   `default_type_enrichment_data` (form-visible defaults), and the
  #   user-saved values — each layer overriding the previous on key collision.
  def enrichment_data
    @enrichment_data ||= base_type_enrichment_data.stringify_keys
                           .merge(default_type_enrichment_data.stringify_keys)
                           .merge(@user_type_enrichment_data)
  end

  # Runtime-only base values (e.g. current `Setting.get(...)` / `Locale.default`).
  #   Part of `enrichment_data` so prompt templates can reference them, but
  #   not exposed to the frontend edit dialog.
  def base_type_enrichment_data
    {}
  end

  # Form-visible defaults for `type_enrichment_data::*` fields. Merged into
  #   `enrichment_data` as a prompt-render fallback and surfaced to the edit
  #   dialog via `AI::Agent#attributes_with_association_ids`.
  def default_type_enrichment_data
    {}
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

  # Placeholder field names are only used to define object attribute selection mappings.
  # The key needs to be known, because this has also some kind of pre-replacement, before the real renderer runs.
  # There is no need to add other keys which are saved below the enrichment_data.
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

  def execution_definition(context: {})
    transform_structure(definition, context:)
  end

  def execution_action_definition
    transform_structure(action_definition_defaults.deep_merge(action_definition))
  end

  def action_definition_defaults
    { skip_blank_values: true }
  end

  def precondition_checks(ticket:)
    []
  end

  # Override in subclasses to contribute values computed from the current run
  #   context (e.g. `context[:ticket]`). Called with `context: {}` when only a
  #   static render is needed (tests, result-structure inspection), so
  #   implementations must handle missing keys gracefully.
  def runtime_type_enrichment_data(context:)
    {}
  end

  def transform_structure(structure, context: {})
    # Convert hash to JSON string manually to avoid escaping ERB tags.
    # The final `-%>\n` gsub compensates for the fact that `to_json` has already
    #   turned real newlines into the two-character escape sequence `\n`, which
    #   ERB's `trim_mode: '-'` cannot trim — see the note in #render_structure.
    structure_json = structure.to_json
                              .gsub('\\u003c%', '<%')
                              .gsub('%\\u003e', '%>')
                              .gsub(%r{-%>\\n}, '-%>')

    replaced_structure    = replace_placeholders(structure_json)
    sanitized_structure   = sanitize_instruction_template(replaced_structure)
    transformed_structure = render_structure(sanitized_structure, context:)

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

  # Runs before `render_structure` to make `trusted: true` safe. See ErbSanitizer
  #   for the full whitelist grammar and security rationale.
  # `runtime_type_enrichment_data(context: {})` is invoked to collect the *names*
  #   of runtime values so they pass the sanitizer's allow-list; the empty
  #   context yields defaults and doesn't need any entity to be present.
  def sanitize_instruction_template(template_string)
    ErbSanitizer.sanitize(
      template_string,
      object_key:    :type_enrichment_data,
      allowed_names: enrichment_data.keys + runtime_type_enrichment_data(context: {}).keys,
    )
  end

  def replace_placeholders(structure_string)
    return structure_string if enrichment_data.blank?

    # Placeholder values can contain user-provided free text. Insert first and let
    #   #sanitize_instruction_template neutralize any disallowed ERB tags.
    placeholder_field_names.each do |placeholder_name|
      placeholder_pattern = "\#{placeholder.#{placeholder_name}}"
      replacement_value = enrichment_data[placeholder_name].to_s

      structure_string = structure_string.gsub(placeholder_pattern) { replacement_value }
    end

    structure_string
  end

  def render_structure(structure, context: {})
    # `trusted: true` is only safe because #sanitize_instruction_template has already
    #   escaped every ERB tag outside the whitelist. Do not flip this flag without
    #   reviewing the sanitizer.
    # `trim_mode: '-'` enables `<%- %>` / `<% -%>` markers so instruction templates
    #   can drop surrounding newlines without bloating the prompt with blank lines.
    NotificationFactory::Renderer.new(
      objects:                { type_enrichment_data: enrichment_data_object(context:) },
      template:               structure,
      escape:                 false,
      url_encode:             false,
      ignore_missing_objects: true,
      trusted:                true,
      trim_mode:              '-',
    ).render(debug_errors: false)
  end

  def enrichment_data_object(context: {})
    combined_data = enrichment_data.merge(runtime_type_enrichment_data(context:).stringify_keys)
    return nil if combined_data.blank?

    sanitized_values = combined_data.values.map { |value| sanitize_template_value(value) }
    Struct.new(*combined_data.keys.map(&:to_sym)).new(*sanitized_values)
  end

  # Values rendered via `#{type_enrichment_data.<name>}` are inserted verbatim into a JSON template and
  #   then through ERB. Free-text values can contain newlines, quotes, or `<%` sequences, which would
  #   break the final JSON.parse or inject ERB. Normalize line endings and escape accordingly.
  def sanitize_template_value(value)
    return value if !value.is_a?(String)

    value
      .gsub(%r{\r\n|\n\r|\r|\n}, "\n")
      .json_escape
      .gsub('<%', '<%%')
  end
end
