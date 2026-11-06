# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The objects a tool works on, loaded and authorized as the current user before it runs: the object the caller named or
#   the conversation's own, and the records its arguments point to.
module Service::AI::Tool::Concerns::ObjectLoading
  extend ActiveSupport::Concern

  private

  # Runs as the current user: the service layer sets it before the tool is created.
  def load_context_object
    declared = self.class.tool_loads
    named    = declared[:locator]&.named?(arguments)
    return if !named && declared[:optional] && surface == :mcp

    gid = named ? named_object_gid(declared) : starting_object_gid(declared[:type])

    object = Gql::ZammadSchema.authorized_object_from_id(gid, type: declared[:type], user: current_user, query: declared[:pundit_method])
    instance_variable_set(:"@#{declared[:name]}", object)
  rescue Exceptions::Forbidden
    raise if !read_only?(gid, declared)

    raise Service::AI::Tool::ReadOnlyError, declared[:locator]::READ_ONLY
  end

  # The object the read tools show, which only a tool that changes it refuses: saying so spares the client looking for a
  #   missing one. An object the user may not read stays not found.
  def read_only?(gid, declared)
    read_access = declared[:locator]&.const_get(:READ_ACCESS)
    return false if read_access.nil? || declared[:pundit_method] == read_access

    Gql::ZammadSchema.authorized_object_from_id(gid, type: declared[:type], user: current_user, query: read_access).present?
  rescue Exceptions::Forbidden
    false
  end

  def starting_object_gid(type)
    return context_object if starting_object_id(type)

    raise Service::AI::Tool::NoContextObjectError, "This conversation is about no #{type.name.underscore.humanize(capitalize: false)}."
  end

  def starting_object_id(type)
    global_id = GlobalID.parse(context_object.to_s)

    global_id.model_id.to_i if global_id&.model_name == type.name
  end

  # The object the caller named. In the harness only one that the conversation named before: a text a tool returned,
  #   such as a customer's message, cannot point the model at another one. Decided before the object is looked for, so
  #   that the answer tells nothing about objects the user may not see.
  #
  # @param given [Hash] the arguments that name it, under the locator's parameter names
  def named_object_gid(declared, given = arguments)
    locator = declared[:locator].new(given)
    raise Service::AI::Tool::NotNamedError, locator.class::NOT_IN_CONVERSATION if surface == :harness && !named_in_conversation?(locator, declared[:type])

    id = locator.record_id
    raise ActiveRecord::RecordNotFound if id.nil?

    Gql::ZammadSchema.id_from_internal_id(declared[:type], id)
  end

  # The conversation's own object, those the agent added as context, those a tool returned as rows, and those the agent
  #   named in their own messages; the conversation is read only for another object than its own. A tool that changes
  #   an object does not count the added ones: changes go to the conversation's own object.
  def named_in_conversation?(locator, type)
    ids = [starting_object_id(type), *(added_object_ids(type) if !self.class.write?)].compact
    return true if locator.named_by?(ids:, texts: [], user: current_user)
    return false if run.nil?

    # By name: the tool comes with the harness.
    returned = Service::AI::Tool::Runtime::Returned.in(conversation: run.conversation, except_tool: 'show_reply_draft')
    texts    = run.conversation.messages.where(role: 'user').pluck(:content)

    locator.named_by?(ids: ids + returned.ids_of(type).to_a, texts:, user: current_user)
  end

  # As the run started: an object added later, or removed since, is not.
  def added_object_ids(type)
    return [] if run.nil?

    run.context_items.filter_map { |item| item['id'] if item['type'] == type.name }
  end

  def load_argument_objects
    self.class.tool_parameters.each do |name, spec|
      next if spec[:loads].nil? || arguments[name].nil?

      id     = Gql::ZammadSchema.id_from_internal_id(spec[:loads], arguments[name])
      object = Gql::ZammadSchema.authorized_object_from_id(id, type: spec[:loads], user: current_user)
      raise Pundit::NotAuthorizedError if !readable?(object)

      instance_variable_set(:"@#{name.delete_suffix('_id')}", object)
    end
  end
end
