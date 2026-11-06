# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A tool of the shared tool layer, used by the agent harness and the MCP server alike. A tool declares what the model
# and the permission check need to know, and implements #execute, which returns a Hash or a Service::AI::Tool::Runtime::Result.
#
# A tool never checks whether it may run at all: Service::AI::Tool::Runtime::PerformCall does that for every call. It uses the
# policies for the objects it touches, as the user it runs for; the object it works on is declared with .loads and
# checked before #execute, as a GraphQL argument declares `loads:`.
class Service::AI::Tool < Service::Base
  EFFECTS  = %i[read write].freeze
  SURFACES = %i[harness mcp].freeze
  TYPES    = {
    string:  ->(value) { value.is_a?(String) },
    integer: ->(value) { value.is_a?(Integer) },
    number:  ->(value) { value.is_a?(Numeric) },
    boolean: ->(value) { [true, false].include?(value) },
    array:   ->(value) { value.is_a?(Array) },
    object:  ->(value) { value.is_a?(Hash) },
  }.freeze

  # The tools of an audience a run sends however many it offers: the most used, so that most questions need no search.
  #   More would leave the model too many to choose from before it searched at all.
  ALWAYS_LOADED_PER_AUDIENCE = 5

  # One message for a missing object and for one the user may not see, so that a tool never reveals what exists.
  #   Written for the model, like every text a tool returns, so not translated.
  NOT_FOUND_MESSAGE = 'The requested object was not found.'.freeze # rubocop:disable Zammad/DetectTranslatableString

  # The system user, which stands for no one: a change it made is the system's, an owner it is is none.
  SYSTEM_USER_ID = 1

  # How to go on after a cursor that does not fit, followed by where a list without one starts.
  CURSOR_HINT = 'Pass it with the same other arguments as the call that returned it, or leave it out to start from'.freeze # rubocop:disable Zammad/DetectTranslatableString

  # A call that needs the conversation's starting object, in a conversation that has none of the declared type.
  class NoContextObjectError < StandardError; end

  # A call of a tool that needs the run, outside the harness.
  class NoRunError < StandardError; end

  # A call in the harness that names another object than the conversation's, which neither the agent nor a tool named.
  class NotNamedError < StandardError; end

  # A write on an object the user may read but not change.
  class ReadOnlyError < StandardError; end

  # A call that names an object by something several objects share, such as an email two users have.
  class AmbiguousNameError < StandardError; end

  requires_current_user!

  class_attribute :tool_description, :tool_effect, :tool_permission, instance_accessor: false
  class_attribute :tool_surfaces, :tool_audiences, instance_accessor: false, default: [].freeze
  class_attribute :tool_parameters, instance_accessor: false, default: {}.freeze
  class_attribute :tool_loads, instance_accessor: false
  class_attribute :tool_surface_descriptions, instance_accessor: false, default: {}.freeze
  class_attribute :tool_title, :tool_output_schema, instance_accessor: false
  class_attribute :tool_mcp_annotations, instance_accessor: false, default: {}.freeze
  class_attribute :tool_searches, :tool_needs_run, :tool_always_loaded, instance_accessor: false, default: false

  include Service::AI::Tool::Concerns::Arguments
  include Service::AI::Tool::Concerns::ObjectLoading

  class << self
    def tool_name
      name.demodulize.underscore
    end

    # Optional display metadata kept with a call; built-in tools have frontend presentation plugins.
    def display_metadata
      {}
    end

    # Every surface gets the text, followed by its own sentences where something holds only there. The MCP projection is
    #   a contract with every client and versioned as one: a change of the shared text changes it too.
    #
    # @param text [String] what the tool does and when to call it, written for the model; over MCP it knows no conversation
    # @param harness [String, nil] what holds only in the harness
    # @param mcp [String, nil] what holds only over MCP
    def description(text, harness: nil, mcp: nil)
      self.tool_description          = text
      self.tool_surface_descriptions = { harness:, mcp: }.compact.freeze
    end

    # @param text [String] how an MCP client shows the tool to people
    def title(text)
      self.tool_title = text
    end

    # @param schema [Hash] the JSON Schema of the hash the tool returns, sent to MCP clients as its output schema
    def output_schema(schema)
      self.tool_output_schema = schema.deep_stringify_keys.freeze
    end

    # @param idempotent_hint [Boolean, nil] whether calling it twice changes nothing more; left out, as for every write
    def mcp_annotations(destructive_hint:, open_world_hint:, idempotent_hint: nil)
      self.tool_mcp_annotations = { destructive_hint:, open_world_hint:, idempotent_hint: }.compact.freeze
    end

    # @param surface [Symbol] :harness or :mcp
    def description_for(surface)
      [tool_description, tool_surface_descriptions[surface]].compact.join(' ')
    end

    # The same for an object that does not exist and one the user may not see; a locator may say where to look instead.
    def not_found_message
      locator = tool_loads&.dig(:locator)
      locator&.const_defined?(:NOT_FOUND, false) ? locator::NOT_FOUND : NOT_FOUND_MESSAGE
    end

    def effect(value)
      self.tool_effect = value
    end

    # @param name [String] an existing permission, such as 'ticket.agent'
    def permission(name)
      self.tool_permission = name
    end

    def offered_in(*surfaces)
      self.tool_surfaces = surfaces.freeze
    end

    # The tool searches: the instructions on searching come with it (AI::Harness::SystemPrompt).
    def searches
      self.tool_searches = true
    end

    # The tool works on the run that calls it, such as to keep something with it: it is offered in the harness only, and
    #   a call without a run is not found.
    def needs_run
      self.tool_needs_run = true
    end

    # The tool is sent to the model however many tools a run offers; the others it finds with search_tools once a run
    #   offers more than AI::Harness::ToolSelection sends at once.
    def always_loaded
      self.tool_always_loaded = true
    end

    # @param names [Array<Symbol>] the audiences whose conversations may offer the tool (AI::Harness::Audience)
    def audiences(*names)
      self.tool_audiences = names.map(&:to_sym).freeze
    end

    # @param items [Hash, nil] for an array, the type of its elements, e.g. { type: 'integer' }
    # @param default [Object, nil] what #argument returns when the model leaves the argument out
    # @param minimum [Numeric, nil] the smallest value of a number
    # @param maximum [Numeric, nil] the largest value of a number
    # @param mcp_default [Object, nil] the default over MCP, where it differs from the harness's
    # @param mcp_description [String, nil] the description over MCP, where the default or the use differs
    # @param loads [Class, nil] the model whose ID the argument is: the object is read and checked with its policy's
    #   show? before #execute, as a GraphQL argument declares `loads:`, and as #readable? checks it, and given to the tool
    #   under the parameter's name without "_id"; a missing object and one the policy refuses are both not found
    def parameter(param_name, type:, description:, required: false, enum: nil, items: nil, default: nil, minimum: nil, maximum: nil, loads: nil, mcp_default: nil, mcp_description: nil)
      raise ArgumentError, "unknown parameter type: #{type.inspect}" if !TYPES.key?(type)
      raise ArgumentError, "unknown item type: #{items.inspect}" if items && !TYPES.key?(items.with_indifferent_access[:type]&.to_sym)
      raise ArgumentError, "bounds need a number: #{param_name}" if (minimum || maximum) && %i[integer number].exclude?(type)
      raise ArgumentError, "an object is loaded by an integer ID: #{param_name}" if loads && (type != :integer || !param_name.to_s.end_with?('_id'))

      self.tool_parameters = tool_parameters.merge(
        param_name.to_s => { type:, description:, required:, enum:, items:, default:, minimum:, maximum:, loads:, mcp_default:, mcp_description: }
      ).freeze

      attr_reader param_name.to_s.delete_suffix('_id') if loads
    end

    # The tool works on the conversation's starting object: it is read again and checked with the policy at every
    #   call, before #execute, and given to the tool under its name. A missing object and one the policy refuses are
    #   both not found.
    #
    # @param type [Class] the model the starting object must be
    # @param pundit_method [Symbol] the policy method, as GraphQL's `loads_pundit_method`
    # @param named [Boolean] the caller may name the object instead, as people know it — a ticket by its number, ID or
    #   link —, checked with the same policy method; over MCP, where there is no conversation, it has to
    # @param starting [Boolean] without a name, the conversation's starting object; false where the caller always names
    #   it, such as a user, as no conversation starts on one
    # @param optional [Boolean] the tool also works without the object: over MCP an unnamed one is none
    def loads(object_name, type:, pundit_method: :show?, named: false, starting: true, optional: false)
      locator = locator_for(type) if named
      raise ArgumentError, "an object of type #{type.name} cannot be named" if named && locator.nil?
      raise ArgumentError, 'an object that is no starting object has to be named' if !starting && !named
      raise ArgumentError, 'only an object the caller names can be left out' if optional && locator.nil?

      self.tool_loads = { name: object_name.to_sym, type:, pundit_method:, locator:, starting:, optional: }.freeze
      locator&.const_get(:PARAMETERS)&.each { |name, spec| parameter(name, **spec) }

      attr_reader object_name
    end

    def write?
      tool_effect == :write
    end

    def search?
      tool_searches
    end

    def needs_run?
      tool_needs_run
    end

    def always_loaded?
      tool_always_loaded
    end

    def offered_in?(surface)
      tool_surfaces.include?(surface)
    end

    def audience?(audience)
      tool_audiences.include?(audience.name)
    end

    # A tool runs nowhere until it declares all of this.
    def declaration_errors
      errors = []
      errors << 'no description' if tool_description.blank?
      errors << 'no effect' if EFFECTS.exclude?(tool_effect)
      errors << 'no permission' if tool_permission.blank?
      errors << 'not offered anywhere' if tool_surfaces.empty? || (tool_surfaces - SURFACES).any?
      errors << 'a description for a surface it is not offered in' if (tool_surface_descriptions.keys - tool_surfaces).any?
      errors.concat(harness_only_errors)
      errors << 'no audience' if tool_audiences.empty?
      errors << 'an unknown audience' if tool_audiences.any? { |audience| AI::Harness::Audience.find(audience).nil? }
      errors
    end

    def declared?
      declaration_errors.empty?
    end

    # Whether the tool can work on this system at all; a tool that cannot is not offered, or the model would call it
    #   and say what it did not find.
    def available?
      true
    end

    # Whether this user may use the tool beyond its permission; a connected server's tool also asks for the server's
    #   roles (Service::AI::Tool::Runtime::ExternalMCP).
    def usable_by?(_user)
      true
    end

    def definition
      AI::Provider::Completion::ToolDefinition.new(name: tool_name, description: description_for(:harness), input_schema:)
    end

    private

    def locator_for(type)
      Service::AI::Tool::Locator.for_type(type)
    end

    # What only a conversation of the harness has: its run and its starting object. Over MCP there is neither.
    def harness_only_errors
      return [] if (tool_surfaces - [:harness]).empty?

      [
        ('needs the run, so it is offered in the harness only' if needs_run?),
        ('loads the starting object, so it is offered in the harness only' if tool_loads && !tool_loads[:locator]),
      ].compact
    end

  end

  attr_reader :arguments, :context_object, :run, :surface, :confirmation

  # @param arguments [Hash] checked against the tool's parameters, with string keys
  # @param context_object [String, nil] the global ID of the conversation's starting object
  # @param run [AI::Harness::Run, nil] the run of the harness that calls the tool, for a tool that needs it
  # @param surface [Symbol] where the call comes from: :harness or :mcp
  def initialize(arguments:, context_object: nil, run: nil, surface: :harness, confirmation: nil)
    @arguments      = arguments
    @context_object = context_object
    @run            = run
    @surface        = surface
    @confirmation   = confirmation

    raise NoRunError, 'This tool works inside a conversation only.' if self.class.needs_run? && run.nil? # rubocop:disable Zammad/DetectTranslatableString

    load_context_object if self.class.tool_loads
    load_argument_objects
  end

  # @return [Object] the argument the model gave, or the parameter's default where it runs when it left it out
  def argument(name)
    value = arguments[name.to_s]
    return value if !value.nil?

    spec = self.class.tool_parameters[name.to_s]
    spec && self.class.parameter_default(spec, surface)
  end

  # Whether the user may see a record, as GraphQL's types check every object they return: a tool builds its result by
  #   hand, so it checks what it returns.
  def readable?(record)
    !!policy_result(record)
  end

  # Whether the user may see a field of a record, as GraphQL's scoped fields decide it: the record's policy answers
  #   show? with true, false or an ApplicationPolicy::FieldScope that allows some fields only. A tool builds its result
  #   by hand, so it asks before it returns a field a scope may deny.
  def field_visible?(record, field)
    result = policy_result(record)

    result.respond_to?(:field_authorized?) ? result.field_authorized?(field) : !!result
  end

  # A user's reference row, with the email only where the policy shows it.
  def visible_user_row(user)
    row = Service::AI::Tool::Output::User.row(user).content

    field_visible?(user, :email) ? row : row.except(:email)
  end

  private

  # The cursor of the next page of a list the tool returns (Service::AI::Tool::Runtime::Cursor).
  def next_cursor_at(offset)
    Service::AI::Tool::Runtime::Cursor.encode(offset:, scope: cursor_scope)
  end

  # @return [Integer, nil] where the page starts: 0 without a cursor, nil for a cursor not given for this list
  def cursor_offset
    Service::AI::Tool::Runtime::Cursor.decode(argument(:cursor), scope: cursor_scope)
  end

  # What makes the list a cursor belongs to: every argument but the cursor and the page size, as the call means it.
  def cursor_scope
    self.class.tool_parameters.keys.excluding('cursor', 'limit').index_with { |name| argument(name) }
  end

  # Once per record and call: a policy may resolve permissions each time it is asked. The knowledge base's policies
  #   read the user's roles, so their answer is narrowed to what a token allows.
  def policy_result(record)
    key = [record.class.name, record.id]
    return policy_results[key] if policy_results.key?(key)

    policy_results[key] = begin
      Service::AI::Tool::Access::KnowledgeBaseLevel.cap(record, Pundit.policy(current_user, record).show?, current_user)
    rescue Pundit::NotAuthorizedError
      false
    end
  end

  def policy_results = @policy_results ||= {}

  # Last, because loading the tools runs their declarations, which need the methods above.
  include Mixin::RequiredSubPaths
end
