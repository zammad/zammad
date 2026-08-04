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

  # The purposes a connection can be the default for, each backed by a `for_<purpose>`
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

  before_save    :remove_blank_config_values, :remove_unsupported_embedding_default, :reset_status_on_config_change
  after_create   :ensure_default_chat, :seed_initial_optional_defaults, :enforce_optional_default_exclusivity
  after_update   :ensure_default_chat, :enforce_optional_default_exclusivity
  before_destroy :protect_online_service_connection
  after_destroy  :ensure_default_chat, :disable_ai_provider_without_connections

  # Reentrancy guard for the default-maintenance callbacks' sibling saves (Ticket::State pattern).
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

  def self.for_embeddings
    return if !Setting.get('ai_provider')

    find_by(default_embedding: true)
  end

  def self.for_ocr
    return if !Setting.get('ai_provider')

    find_by(default_ocr: true)
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

    # Explicitly trigger the client notification, because update_columns skips callbacks and the
    # notification is not a database change that would otherwise fire it. However, keeping it in
    # place avoids the audit, search-index, and default-maintenance callbacks of a regular save.
    notify_clients_after_update
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

  # Keeps exactly one connection flagged `default_chat` (Ticket::State pattern): promotes the
  # oldest connection when none is left, and clears the flag off every other connection when
  # this one just got it.
  def ensure_default_chat
    return if callback_loop

    connections_with_default = AI::ProviderConnection.where(default_chat: true)
    return if connections_with_default.one?

    if connections_with_default.none?
      promote_default('default_chat')
    else
      clear_other_defaults('default_chat')
    end
  end

  # Unlike `default_chat`, `default_embedding`/`default_ocr` are optional and not
  # auto-maintained: a connection carrying neither simply means that purpose is unconfigured
  # (for_embeddings/for_ocr return nil) — clearing a flag just turns the purpose off, with no
  # promotion of a replacement. Only the very first connection ever created is seeded with both
  # (embedding only if it actually supports it), so a fresh single-connection install works out
  # of the box.
  def seed_initial_optional_defaults
    return if callback_loop
    return if AI::ProviderConnection.many?

    connection = AI::ProviderConnection.find(id)
    connection.default_embedding = true if connection.embedding_capable
    connection.default_ocr       = true
    connection.callback_loop     = true
    connection.save!
  end

  # At most one connection may carry `default_embedding`/`default_ocr` at a time: flagging one
  # here clears it off every other connection that had it.
  def enforce_optional_default_exclusivity
    return if callback_loop

    clear_other_defaults('default_embedding') if default_embedding?
    clear_other_defaults('default_ocr') if default_ocr?
  end

  # Flags the oldest existing connection with `field`; a no-op when there is none left at all.
  def promote_default(field)
    connection = AI::ProviderConnection.reorder(:created_at).first
    return if connection.nil?

    connection[field] = true
    connection.callback_loop = true
    connection.save!
  end

  # Clears `field` off every connection but this one.
  def clear_other_defaults(field)
    AI::ProviderConnection.where(field => true).where.not(id:).find_each do |other|
      other[field] = false
      other.callback_loop = true
      other.save!
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
