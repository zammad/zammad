# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::MCPServer::Confirmation < Service::Base
  # How long the user has to answer; the request state the client echoes back expires with it.
  TTL = 10.minutes

  # Some clients announce forms but decline each without showing it, which reads like the user's no.
  # rubocop:disable-next Zammad/DetectTranslatableString
  NOT_CONFIRMED = 'The action was not confirmed: the user declined, or their client declined the confirmation form without showing it, as some clients do. ' \
                  'Nothing was changed. Do not retry on your own; if the user saw no form, tell them their client cannot show Zammad\'s confirmation.'.freeze

  # What a tool gets to ask its user: #call with the prepared action, and whether the call carries the user's answer.
  Asker = Data.define(:user, :token, :tool_name, :server_context) do
    def call(**prepared)
      Service::MCPServer::Confirmation.execute(user:, token:, tool_name:, server_context:, **prepared)
    end

    def continuing?
      Service::MCPServer::Confirmation.continuing?(server_context)
    end

    def form?
      Service::MCPServer::Confirmation.form?(server_context)
    end
  end

  def self.asker(user:, token:, tool_name:, server_context:)
    Asker.new(user:, token:, tool_name:, server_context:)
  end

  def self.continuing?(server_context)
    !server_context.request_state.nil? || !server_context.input_responses.nil?
  end

  # Whether the client can show its user a form: only in the stateless lifecycle, where the call returns the question.
  def self.form?(server_context)
    return false if !server_context.modern?

    capabilities = server_context.client_capabilities&.with_indifferent_access
    elicitation = capabilities&.dig(:elicitation)
    elicitation.is_a?(Hash) && (elicitation.key?(:form) || !elicitation.key?(:url))
  end

  attr_reader :user, :token, :tool_name, :server_context, :snapshot, :preview, :fields, :declined

  # @param fields [Hash{String => Hash}, nil] values to ask the user for, each a flat JSON Schema property of the form;
  #   the accepted continuation returns them. An empty hash asks for a yes alone that the tool tells apart from a client
  #   that cannot ask: accepted, it returns an empty hash.
  # @param declined [Service::AI::Tool::Runtime::Result, nil] what to answer where the user declines, for a tool that can say
  #   more than that nothing changed
  def initialize(user:, token:, tool_name:, server_context:, snapshot:, preview:, required:, fields: nil, declined: nil)
    @user = user
    @token = token
    @tool_name = tool_name
    @server_context = server_context
    @snapshot = snapshot
    @preview = preview
    @required = required
    @fields = fields
    @declined = declined
  end

  # @return [Service::AI::Tool::Runtime::Result, Hash, nil] the request to the client or a refusal; with fields, the values the
  #   user gave; nil to go on
  #
  # The tool revalidates its snapshot and invokes confirmation inside the transaction containing its write.
  # Consuming approval there makes both changes roll back together if the write fails.
  # Written for the client and model; the form label is translated in CallTool.
  # rubocop:disable Zammad/DetectTranslatableString
  def execute
    return refused('Confirmation was cancelled. Nothing was changed.') if server_context.cancelled? && !continuing?
    return refused('This client cannot continue this confirmation. Start a new call.') if continuing? && !supported?
    return if !required? && !continuing?
    return if !supported?

    scope = fingerprint
    return continuation(scope) if continuing?

    request_confirmation(scope)
  end

  private

  def request_confirmation(scope)
    approval = AI::MCPConfirmation.create!(request_id: SecureRandom.uuid, action_digest: scope, expires_at: TTL.from_now)
    Service::AI::Tool::Runtime::Result.confirmation_required({ request_state: approval.request_id, input_key:, requested_schema: }.compact, text: preview)
  end

  def input_key
    fields ? 'values' : 'confirm'
  end

  def requested_schema
    return if !fields

    { type: 'object', properties: fields, required: fields.keys.presence }.compact
  end

  def required?
    @required
  end

  def continuing?
    self.class.continuing?(server_context)
  end

  def supported?
    self.class.form?(server_context)
  end

  def continuation(scope)
    request_id = server_context.request_state
    return refused('The confirmation expired, was already used or the action changed. Start a new call to review it again.') if !consume(request_id, scope)
    return refused('Confirmation was cancelled. Nothing was changed.') if server_context.cancelled?

    response = server_context.input_response(input_key)
    response = response.with_indifferent_access if response.is_a?(Hash)
    # Accepting is the yes, as clients offer it: the form holds only the values a tool needs.
    return declined || refused(NOT_CONFIRMED) if !response.is_a?(Hash) || response[:action] != 'accept'

    given_values(response[:content]) if fields
  end

  def given_values(content)
    values = (content.is_a?(Hash) ? content : {}).to_h.stringify_keys.slice(*fields.keys)
    return refused('Not every value was given. Nothing was changed.') if fields.keys.any? { |key| values[key].nil? }

    values
  end

  def consume(request_id, scope)
    return false if !request_id.is_a?(String)

    now = Time.current
    # Checking and consuming must be one SQL statement so concurrent continuations cannot both succeed.
    AI::MCPConfirmation.where(request_id:, action_digest: scope, consumed_at: nil)
      .where('expires_at > ?', now)
      .update_all(consumed_at: now, updated_at: now) == 1 # rubocop:disable Rails/SkipsModelValidations
  end

  def fingerprint
    Digest::SHA256.hexdigest({
      user_id:   user.id,
      token_id:  token&.id,
      tool_name:,
      snapshot:,
      preview:,
      required:  required?,
      fields:,
    }.to_json)
  end

  def refused(message)
    Service::AI::Tool::Runtime::Result.error('confirmation_required', message)
  end
  # rubocop:enable Zammad/DetectTranslatableString
end
