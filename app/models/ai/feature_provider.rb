# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Per-feature provider routing: maps an AI service `identifier` to the AI::ProviderConnection
# (and options) that should serve it. Resolved at runtime via AI::ProviderConnection.for_chat.
class AI::FeatureProvider < ApplicationModel
  # Derived from the registered AI feature services — a new service becomes routable
  # automatically. OCR is excluded: it is a capability resolved per connection
  # (AI::ProviderConnection.for_ocr).
  def self.available_identifiers
    Service::AI::Feature.identifiers.map(&:to_s) - [Service::AI::Feature::OCR.identifier]
  end

  # The feature's routing options (e.g. a temperature override); {} without a routing row.
  def self.options_for(identifier)
    find_by(identifier: identifier.to_s)&.options&.symbolize_keys || {}
  end

  belongs_to :provider_connection,
             class_name: 'AI::ProviderConnection',
             inverse_of: :feature_providers

  validates :identifier,
            presence:   true,
            uniqueness: { case_sensitive: false },
            inclusion:  { in: ->(_record) { available_identifiers } }
end
