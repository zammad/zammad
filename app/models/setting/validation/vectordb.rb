# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Guards the knowledge base assistant master switch: the vector database is only usable with an
# AI provider that can actually generate embeddings, and with AI switched on at all.
class Setting::Validation::VectorDB < Setting::Validation::Base

  def run
    return result_success if !value

    # Looked up without the AI kill switch that `AI::ProviderConnection.for_embeddings` honors: with
    # AI off it answers nothing whatever is configured, so asking it first would tell an admin who
    # has configured an embedding model perfectly well that they have not. The two conditions
    # together are what that method answers - reported apart, so each names what to fix.
    return result_failed(__('No AI provider with a valid embedding model is configured.')) if !AI::ProviderConnection.exists?(default_embedding: true)

    # Same wording as the alert the AI feature screens show for this condition
    # (app/assets/javascripts/app/views/ai/missing_provider_alert.jst.eco), minus its |…| emphasis:
    # that markup is understood by the frontend translation only, and a validation message is read
    # from the console, the API and the logs as well.
    return result_failed(__('The provider configuration is disabled. Before proceeding, please enable it in AI > Providers.')) if !Setting.get('ai_provider')

    result_success
  end

end
