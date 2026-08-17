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

  # The two config values that describe the embedding model in numbers, with the message for a
  # value that is none. Each names the field as the dialog labels it, so an admin reading the
  # error knows which one to fix.
  EMBEDDING_METADATA_MESSAGES = {
    embedding_size:        __('The embedding dimensions must be a positive number.'),
    embedding_input_limit: __('The context window size must be a positive number.'),
  }.freeze

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
  validate  :embedding_model_present_when_serving_embeddings
  validate  :embedding_metadata_must_be_positive

  before_validation :drop_stale_embedding_default
  before_save       :remove_blank_config_values, :seed_recommended_embedding_model,
                    :remove_unconfigurable_embedding_model,
                    :remove_unsupported_embedding_default, :reset_status_on_config_change
  after_create   :ensure_default_chat, :seed_initial_optional_defaults, :enforce_optional_default_exclusivity
  after_update   :ensure_default_chat, :enforce_optional_default_exclusivity
  before_destroy :protect_online_service_connection
  after_destroy  :ensure_default_chat, :disable_ai_provider_without_connections
  # Every commit, not `on: %i[create update]`: the default maintenance above saves the record again
  # within the create's transaction, and a save that changes nothing replaces the trigger action the
  # `on:` filter matches - the callback would silently never run for a newly created connection. A
  # destroy needs no special case either: nothing serving embeddings reconciles to nothing.
  after_commit :reconcile_vector_index

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

  # Flags this connection as the one serving embeddings, if it can serve them at all. Serving them
  # requires a named model (see the validation), so the provider's recommendation is written where
  # the admin named none - the same value the former silent fallback resolved to, except now
  # visible in the dialog and recorded with the vectors. Saving a connection names it already
  # (#seed_recommended_embedding_model); this is what still resolves it for a flag set on a stored
  # connection whose config no save has touched since (the one-click action of the admin table).
  #
  # Where no model can be named at all (a custom endpoint serves whatever was deployed there), the
  # flag is cleared rather than left standing: a connection flagged without a model is a record its
  # own validation rejects, which would take the next save of any sibling connection down with it.
  def seed_embedding_default
    if !embedding_capable
      self.default_embedding = false
      return
    end

    # A provider serving a fixed model (Zammad AI) needs nothing in the config to serve embeddings.
    if provider_klass.embedding_model_fallback.present?
      self.default_embedding = true
      return
    end

    model = configured_embedding_model.presence || seedable_recommendation

    if model.blank?
      self.default_embedding = false
      return
    end

    write_embedding_model(model)
    self.default_embedding = true
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

  # State-based rather than event-based: compares what the index holds (Configuration.indexed)
  # against what is configured now (Configuration.current) and enqueues a rebuild on a mismatch. This
  # is why it does not matter which instance or which save of the transaction runs it - a single
  # admin action can touch two records (see #enforce_optional_default_exclusivity), and every one of
  # them arrives at the same comparison. Hooked onto the model rather than onto the controller: the
  # admin dialog, the REST API and `rails console` all write these records, and only one of them goes
  # through a controller.
  def reconcile_vector_index
    Service::AI::VectorDB::Reconcile.execute
  end

  # The provider's recommendation, unless the model listing contradicted it: a listing the dialog
  # fetched that carried models but not the one the recommendation names means the provider does
  # not serve it - the wizard deliberately left the field empty, and seeding the recommendation
  # behind its back would flag the connection onto a model the endpoint cannot embed with.
  #
  # The listing service is asked for that verdict rather than for the listing itself, so it survives
  # the catalogue it came from (Service::AI::ProviderConnection::ListModels::UNLISTED_RECOMMENDATION_TTL):
  # a save arrives after however long the admin spent in the dialog, and an expired catalogue must
  # not read as permission to seed what the dialog was told is not served. Never fetched either way -
  # a model callback is no place for a provider round-trip.
  #
  # Where no listing said anything against it, the recommendation stands: connections created through
  # the API or the console, and the migration backfill. An empty listing does say something, though -
  # an Ollama with nothing pulled serves nothing, the recommendation included, and the dialog offers
  # it no more than its dropdown does: the field it leaves empty there is one the admin has to fill
  # to serve embeddings.
  def seedable_recommendation
    recommendation = provider_klass.recommended_embedding_model
    return nil if recommendation.blank?
    return nil if Service::AI::ProviderConnection::ListModels.recommendation_unlisted?(provider:, config: config.to_h)

    recommendation
  end

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

  # What the empty option of the dialog's embedding model dropdown promised, written into the config
  # of every connection rather than only of the one that ends up serving embeddings: the label names
  # the recommendation ('Default (text-embedding-3-small)'), and the numbers describing it are
  # submitted along with it - so the model they describe has to be recorded too. Nothing resolves an
  # unnamed one at request time anymore (see AI::Provider#embedding_model!), which is what makes a
  # config carrying the dimensions of a model it does not name a config that describes nothing.
  #
  # This used to happen as a side effect of seeding the embedding default (#seed_embedding_default),
  # which only ever runs for the very first connection of an install - leaving every later one with
  # the metadata of a model whose name was dropped as a blank value.
  #
  # Only for a config this very save writes, following the same rule as
  # embedding_metadata_must_be_positive: an unrelated save of a legacy connection - the rename that
  # the stale flag fix-up serves, or the default flag maintenance of a sibling - must not start
  # writing config values of its own, which would also reset the recorded status along the way.
  def seed_recommended_embedding_model
    return if !new_record? && !config_changed?
    return if !embedding_capable
    # A provider serving a fixed model has none to name in the config (Zammad AI).
    return if provider_klass.embedding_model_fallback.present?
    return if configured_embedding_model.present?

    recommendation = seedable_recommendation
    return if recommendation.blank?

    write_embedding_model(recommendation)
  end

  # Symbol keys in memory (a config built in Ruby), string keys once loaded from the database - so
  # the merge has to happen on one kind of key, or the config ends up with both.
  def write_embedding_model(model)
    self.config = config.to_h.stringify_keys.merge('embedding_model' => model)
  end

  # The connection serving embeddings has to name its model. Without this, Setting::Validation::VectorDB
  # would keep passing for a connection that cannot embed at all, and the failure would only
  # surface when indexing runs.
  #
  # Not enforced for a provider that cannot embed: there the flag is dropped by
  # remove_unsupported_embedding_default anyway, and rejecting the record instead would make a
  # provider change (e.g. OpenAI → Anthropic) fail rather than simply turn the purpose off.
  def embedding_model_present_when_serving_embeddings
    return if !default_embedding
    return if !embedding_capable
    # A provider serving a fixed model has none to configure (Zammad AI).
    return if provider_klass.embedding_model_fallback.present?
    return if configured_embedding_model.present?

    errors.add(:base, __('An embedding model must be configured for the connection used for embeddings.'))
  end

  # Symbol keys in memory (a config built in Ruby), string keys once loaded from the database.
  def configured_embedding_model
    config.to_h.symbolize_keys[:embedding_model]
  end

  # How long the vectors of the embedding model are and how many tokens it takes at once: numbers
  # that describe a model, so zero or less describes none. The dialog constrains its fields, and
  # this is what keeps an API or console write from persisting a value that would only fail once
  # indexing runs - the vector table cannot be built with such a dimension
  # (Service::AI::VectorDB::CreateTable), and the chunker raises on a budget that leaves no room
  # for content.
  #
  # Absent stays valid: a model no source could size is stored without them, and both consumers
  # fall back to what they know about the model.
  #
  # Only a config this very save writes is checked, following the same rule as
  # drop_stale_embedding_default: a value the API allowed in before this validation existed would
  # otherwise make every later save of the record fail - down to the default flag maintenance of its
  # siblings - over data no save of it touches, while both consumers already fall back where the
  # config holds no usable number.
  def embedding_metadata_must_be_positive
    return if !new_record? && !config_changed?

    values = config.to_h.symbolize_keys

    EMBEDDING_METADATA_MESSAGES.each do |key, message|
      value = values[key]
      # A cleared dialog field arrives as '' and is dropped by remove_blank_config_values.
      next if value.blank?
      next if positive_integer?(value)

      errors.add(:base, message)
    end
  end

  # The config is jsonb and keeps whatever was written into it, down to a string ('1024') - which
  # the consumers parse back into a number, so that is what this checks rather than the type alone.
  def positive_integer?(value)
    Integer(value.to_s, exception: false)&.positive? || false
  end

  # A flag that was already set and can no longer be honoured is dropped instead of rejected: it is
  # legacy data whose model came from the former silent fallback, and rejecting it would take down
  # every maintenance save of a sibling connection (see the default flag callbacks) along with the
  # migration that introduced this rule.
  #
  # Only such an untouched record, though: setting the flag or editing the config in this very save
  # is a deliberate change, and has to surface as the validation error rather than quietly turn
  # semantic search off. Every legacy fix-up path this serves writes flag columns alone.
  def drop_stale_embedding_default
    return if !default_embedding
    return if changes_to_save.key?('default_embedding')
    return if changes_to_save.key?('config')
    return if !embedding_capable # remove_unsupported_embedding_default owns that case
    return if provider_klass.embedding_model_fallback.present?
    return if configured_embedding_model.present?

    self.default_embedding = false
  end

  # The embedding model of a provider that serves a fixed one (Zammad AI) is not part of its config:
  # the dialog offers no field for it and submits nothing. A value that reaches this anyway - a
  # hand-written API call, or a config carried over from another provider - would decide what the
  # vectors are built with for a model the admin cannot see, so it is dropped.
  def remove_unconfigurable_embedding_model
    return if provider_klass&.embedding_model_fallback.blank?

    self.config = config.to_h.except('embedding_model', :embedding_model)
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
    connection.seed_embedding_default
    connection.default_ocr   = true
    connection.callback_loop = true
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
