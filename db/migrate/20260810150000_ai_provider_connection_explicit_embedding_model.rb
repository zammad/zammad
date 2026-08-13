# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The embedding model used to be resolved from the adapter's DEFAULT_OPTIONS at request time, so a
# connection serving embeddings could carry none. Now that it has to name its model, those
# connections are backfilled with the provider's recommendation - the very value the former
# fallback resolved to, so nothing changes semantically for them. Without it semantic search would
# break silently, and the connection would be rejected on its next save.
class AIProviderConnectionExplicitEmbeddingModel < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    AI::ProviderConnection.where(default_embedding: true).each do |connection|
      backfill(connection)
    end
  end

  private

  # Same rule as the connection seeding: name the recommendation, leave a provider serving a fixed
  # model alone, and clear the flag where no model can be named at all. That last case (a custom
  # endpoint serves whatever was deployed there) leaves semantic search unconfigured until an admin
  # picks a model - which the dialog now offers a field for. Keeping the flag instead would persist
  # a record that its own validation rejects, taking the next save of any sibling down with it.
  def backfill(connection)
    return if connection.config['embedding_model'].present?
    # An unknown provider key would fail its own validation and abort the upgrade over data this
    # migration is not here to fix.
    return if connection.provider_klass.nil?

    connection.seed_embedding_default

    # Anything else the record is rejected for is data this migration is not here to fix either -
    # e.g. an embedding dimension or input limit stored as zero or less, which only an API write
    # ever allowed. Left as it is rather than aborting the upgrade over it.
    if !connection.valid?
      Rails.logger.warn "AI provider connection '#{connection.name}' could not be given an embedding model: #{connection.errors.full_messages.join(' ')} Semantic search is unconfigured until this is corrected."
      return
    end

    connection.save!

    return if connection.default_embedding

    Rails.logger.warn "AI provider connection '#{connection.name}' served embeddings without a model, and #{connection.provider} has none to fall back to. Semantic search is unconfigured until an embedding model is set for it."
  end
end
