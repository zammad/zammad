# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Guards the knowledge base assistant master switch: the vector database is only usable with an
# AI provider that can actually generate embeddings.
class Setting::Validation::VectorDB < Setting::Validation::Base

  def run
    return result_success if !value
    return result_success if AI::ProviderConnection.for_embeddings.present?

    result_failed(__('No AI provider with a valid embedding model is configured.'))
  end

end
