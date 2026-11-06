# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The fields of one record for one user, as Core Workflow computes them for a screen: each field's type, whether it is
#   shown and required, and the stored values it allows — for the record as it is, or with changes, as the screen shows
#   it after a change. Every client that reads or sets fields gets them from here, so that what a client may choose and
#   what Zammad accepts on save come from the same rules.
class Service::EntityAttribute::Metadata < Service::Base
  # A field of the record; allowed is nil where Core Workflow restricts none.
  Entry = Data.define(:attribute, :type, :shown, :required, :allowed) do
    def name
      attribute.name
    end

    # @return [Array<Array(String, String)>, nil] the allowed values as stored, each with its label; nil for a field
    #   without a list
    def choices
      type.choices(allowed:)
    end

    def label(value)
      return if value.nil? || value == '' || value == []

      type.label(value)
    end

    # The value as a person reads it: free text as plain text, everything else by its label.
    def value_text(value)
      return label(value) if !type.free_text?
      return if value.blank?

      type.plain(value)
    end
  end

  # Hidden fields still hold a value, removed ones none; neither is shown.
  NOT_SHOWN = %w[hide remove].freeze

  # The screens whose fields a Core Workflow screen covers: a new ticket's title and customer stand above the create
  #   form's middle part, which Core Workflow computes.
  ATTRIBUTE_SCREENS = { 'create_middle' => %w[create_top create_middle] }.freeze

  requires_current_user!

  attr_reader :record, :changes, :screen

  # @param record [ApplicationModel] a record whose model checks Core Workflow, such as a ticket
  # @param changes [Hash{String => Object}] stored values by attribute name, such as the ID of another group
  # @param screen [String] the Core Workflow screen, such as 'edit', or 'create_middle' for a record not saved yet
  # @param rules [Boolean] whether to run Core Workflow; without, every field is shown, optional and unrestricted, for a
  #   caller that only needs the fields and their types
  def initialize(record:, changes: {}, screen: 'edit', rules: true)
    @record  = record
    @changes = changes
    @screen  = screen
    @rules   = rules
  end

  # @return [Array<Entry>] the fields of the screen the user may see, in the screen's order
  def execute
    attributes.map do |attribute|
      Entry.new(
        attribute:,
        type:      Service::EntityAttribute::Type.for(attribute, user: current_user, record:),
        shown:     NOT_SHOWN.exclude?(result.dig(:visibility, attribute.name)),
        required:  result.dig(:mandatory, attribute.name) == true,
        allowed:   result.dig(:restrict_values, attribute.name),
      )
    end
  end

  private

  def attributes
    # A record not saved yet has no group to grant access: the screens are read for the user, as the create form does.
    ObjectManager::Object.new(record.class.name).attributes(current_user, record.new_record? ? nil : record, data_only: false)
      .select { |element| ATTRIBUTE_SCREENS.fetch(screen, [screen]).any? { |name| shown_on?(element, name) } }
      .map(&:attribute)
  end

  def shown_on?(element, name)
    element.screens[name].present? && element.screens[name]['shown'] != false
  end

  def result
    return {} if !rules?

    @result ||= CoreWorkflow.perform(payload:, user: current_user, assets: false)
  end

  def rules?
    @rules
  end

  def payload
    {
      'event'      => 'core_workflow',
      'request_id' => 'field_metadata',
      'class_name' => record.class.name,
      'screen'     => screen,
      'params'     => record.attributes.merge(changes).merge('id' => record.id),
    }
  end
end
