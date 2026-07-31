# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A reusable, credentialed handle to an AI provider endpoint; features can share one
# connection (see AI::FeatureProvider). Secrets in `config` are masked on serialization
# (CanMaskConfigSecrets), not encrypted at rest.
class AI::ProviderConnection < ApplicationModel
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch
  include CanMaskConfigSecrets
  include ChecksClientNotification
  include HasAuditLogs

  # The purposes a connection can be the default for, each backed by a `default_<purpose>`
  # column. Keeps callers from deriving column names from unvalidated input.
  DEFAULT_PURPOSES = %w[chat embedding ocr].freeze

  # The search index gets the raw attributes (no masking hook), so `config` would ship the
  # provider token to Elasticsearch in plaintext. Neither column is searched: `status` is
  # machine state, and both are jsonb without a `flattened` mapping, which would additionally
  # let a type change of one config key reject the whole document.
  search_index_attributes_ignored :config, :status

  has_many :feature_providers,
           class_name: 'AI::FeatureProvider',
           inverse_of: :provider_connection,
           dependent:  :destroy

  validates :name,     presence: true, uniqueness: { case_sensitive: false }
  validates :provider, presence: true
  validate  :provider_must_be_known
  validate  :prevent_zammad_ai_provider_changes_on_saas

  before_save   :remove_blank_config_values, :remove_unsupported_embedding_default, :reset_status_on_config_change
  after_create  :ensure_defaults
  after_update  :ensure_defaults
  before_destroy :protect_online_service_connection
  after_destroy :ensure_defaults, :disable_ai_provider_without_connections

  # Reentrancy guard for ensure_defaults's sibling saves (Ticket::State pattern).
  attr_accessor :callback_loop

  def self.chat_connection
    all.detect(&:default_chat?)
  end

  def self.embedding_connection
    all.detect(&:default_embedding?)
  end

  def self.ocr_connection
    all.detect(&:default_ocr?)
  end

  # Resolution: which connection serves a feature. All methods honor the global
  # `ai_provider` kill switch — also at job execution time, so work queued before a disable
  # never reaches the provider.

  # The feature's routing row (AI::FeatureProvider) → the `default_chat` connection. Skipped
  # entirely when identifier is blank, rather than queried with an empty key.
  def self.for_chat(identifier)
    return if !Setting.get('ai_provider')

    routed = AI::FeatureProvider.find_by(identifier: identifier.to_s)&.provider_connection if identifier.present?

    routed || find_by(default_chat: true)
  end

  # The feature's routing row, but only if it actually supports embeddings (a chat-only
  # provider routed for a feature is useless here) → the `default_embedding` connection. No
  # `default_chat` fallback: an embedding call on a provider without embedding support would
  # just fail, so a missing default is logged instead of silently substituted.
  def self.for_embeddings(identifier)
    return if !Setting.get('ai_provider')

    routed = AI::FeatureProvider.find_by(identifier: identifier.to_s)&.provider_connection if identifier.present?
    return routed if routed&.embedding_capable

    default = find_by(default_embedding: true)
    return default if default

    Rails.logger.error('AI::ProviderConnection.for_embeddings: no connection is flagged default_embedding.')
    nil
  end

  # `identifier` is the calling feature's identifier, not OCR's own — OCR has no routing row
  # of its own (AI::FeatureProvider excludes it). Skipped entirely when blank, rather than
  # queried with an empty key: the calling feature's routing row (if any) → the connection
  # flagged `default_ocr` → the `default_chat` connection.
  def self.for_ocr(identifier)
    return if !Setting.get('ai_provider')

    routed = AI::FeatureProvider.find_by(identifier: identifier.to_s)&.provider_connection if identifier.present?

    routed || find_by(default_ocr: true) || find_by(default_chat: true)
  end

  # The AI::Provider adapter class for this connection (e.g. AI::Provider::OpenAI).
  def provider_klass
    AI::Provider.by_name(provider)
  end

  # The configured adapter instance for this connection; nil for an unknown provider.
  def provider_instance(options: {})
    provider_klass&.new(
      config:         config.deep_symbolize_keys,
      options:        options.compact.symbolize_keys,
      # Attributes the HTTP logs of this provider to the connection, so the admin log can link back.
      related_object: self,
    )
  end

  # Runs a real provider call (ask/embed) and records its outcome as this connection's
  # stored health status (Channel#deliver shape): ok on success, error + message on a
  # provider RequestError/ResponseError. Result and errors pass through; non-provider
  # errors (Zammad-side bugs) never touch the status.
  #
  # An unusable reply is not a status either: the endpoint answered, so the connection is
  # reachable and configured — only the model's output was not what the feature asked for.
  # Stamping it would make the health check report the connection as inaccessible until the
  # next successful call, for what is a content hiccup the caller already handles.
  def record_call
    result = yield
    record_status_ok!
    result
  rescue AI::Provider::OutputFormatError
    raise
  rescue AI::Provider::RequestError, AI::Provider::ResponseError => e
    record_status_error!(e.message)
    raise
  end

  def embedding_capable
    provider_klass&.supports_embeddings? || false
  end

  # Stored health status (channel-style), written by record_call and read by the health
  # checker and the admin table badge. `status` holds { 'state' => 'ok'|'error', 'message',
  # 'at' }; {} = never used. update_column on purpose: this fires on every AI request and
  # must not run callbacks.
  def record_status_ok!
    return if status['state'] == 'ok'

    write_status('ok')
  end

  def record_status_error!(message)
    return if status['state'] == 'error' && status['message'] == message.to_s

    write_status('error', message)
  end

  def status_error?
    status['state'] == 'error'
  end

  private

  def write_status(state, message = nil)
    value = { 'state' => state, 'at' => Time.current.iso8601 }
    value['message'] = message.to_s if message.present?

    # updated_at moves along on purpose: the asset loader in the frontend discards an incoming
    # record that is not newer than the cached one, so the admin table would keep rendering the
    # previous status badge. Only a state change gets here, so this does not churn on every call.
    update_columns(status: value, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end

  # Editing the config or provider invalidates the stored status (it reflects the old config);
  # the next real call re-stamps it.
  def reset_status_on_config_change
    return if !config_changed? && !provider_changed?

    self.status = {}
  end

  # Keeps the invariant at the model (not just the controller ping), so migrations and
  # console cannot persist a connection that resolves to no adapter.
  def provider_must_be_known
    return if provider.blank?
    return if AI::Provider.by_name(provider).present?

    errors.add(:provider, __('is not a supported AI provider'))
  end

  # Cleared dialog fields arrive as '' and would override provider defaults in resolution.
  def remove_blank_config_values
    self.config = config.reject { |_k, v| v.is_a?(String) && v.blank? }
  end

  # A provider change can invalidate the embedding default (e.g. OpenAI → Anthropic).
  def remove_unsupported_embedding_default
    return if !default_embedding && !changes_to_save['default_embedding']
    return if embedding_capable

    self.default_embedding = false
  end

  # Keeps exactly one connection flagged as default (Ticket::State pattern): promotes the oldest
  # suitable connection when none is left — for `default_embedding` the oldest one that can
  # actually embed — and clears the others when a new one is set.
  def ensure_defaults
    return if callback_loop

    %w[default_chat default_embedding default_ocr].each do |default_field|
      connections_with_default = AI::ProviderConnection.where(default_field => true)
      next if connections_with_default.one?

      if connections_with_default.none?
        connections = AI::ProviderConnection.reorder(:created_at)
        next if connections.empty?

        connections.each do |connection|
          next if default_field == 'default_embedding' && !connection.embedding_capable

          connection[default_field] = true
          connection.callback_loop = true
          connection.save!
          break
        end

        next
      end

      AI::ProviderConnection.all.each do |other|
        next if other.id == id
        next if other[default_field] == false

        other[default_field] = false
        other.callback_loop = true
        other.save!
        next
      end
    end
  end

  # Deleting the last connection turns the global switch off (mirrors emptying the provider
  # config pre-connections); the inverse is enforced by Setting::Validation::AIProvider.
  def disable_ai_provider_without_connections
    return if AI::ProviderConnection.exists?
    return if !Setting.get('ai_provider')

    Setting.set('ai_provider', false)
  end

  # On SaaS the Zammad AI connection is platform-provisioned and must not be deleted.
  # Raises (not throw :abort) so the REST destroy responds with 422.
  def protect_online_service_connection
    return if !Setting.get('system_online_service')
    return if provider != 'zammad_ai'

    raise Exceptions::UnprocessableContent, __('Cannot delete the Zammad AI connection on this system.')
  end

  # On SaaS, provider "zammad_ai" can only be set by the platform provisioning: blocks
  # creating such a connection here and editing the provider away from it (which would
  # dodge the delete guard above).
  def prevent_zammad_ai_provider_changes_on_saas
    return if !Setting.get('system_online_service')
    return if !provider_changed?
    return if provider != 'zammad_ai' && provider_was != 'zammad_ai'

    errors.add(:provider, __('The Zammad AI connection is managed by the platform and cannot be created or changed here.'))
  end
end
