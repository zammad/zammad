# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Feature::OCR < Service::AI::Feature
  def self.identifier
    'ocr'
  end

  def self.lookup_attributes(context_data, _locale)
    {
      identifier:,
      related_object_id: context_data[:store].store_file_id,
    }
  end

  def self.lookup_version(context_data, _locale)
    context_data[:store].store_file.sha
  end

  def analytics?
    true
  end

  def persistable?
    true
  end

  private

  # Resolved via AI::ProviderConnection.for_ocr, that considers default connection only,
  #   since OCR is a capability, not a routable feature (AI::FeatureProvider excludes it from routing).
  def connection
    @connection ||= AI::ProviderConnection.for_ocr ||
                    raise(__('AI provider is not configured.'))
  end

  def options
    {
      temperature: 0.1,
    }
  end

  def json_response?
    false
  end
end
