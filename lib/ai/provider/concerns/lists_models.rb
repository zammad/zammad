# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider
  # Model listing for the providers whose endpoint can enumerate its models, and the single place
  # where a model's capabilities are derived when the provider does not report them itself.
  #
  # Including this declares supports_model_listing?; the provider still has to implement
  # .models(config, related_object:) with its own endpoint and payload.
  module Concerns::ListsModels
    extend ActiveSupport::Concern

    # Listing models is a metadata read, not inference, so it does not get the generous AI
    # timeouts: an admin waiting for the dropdown has to see a failure quickly instead.
    MODEL_LIST_TIMEOUT_OPTIONS = {
      read_timeout:  ENV.fetch('ZAMMAD_HTTP_AI_MODEL_LIST_TIMEOUT', 30).to_i,
      total_timeout: ENV.fetch('ZAMMAD_HTTP_AI_MODEL_LIST_TIMEOUT', 30).to_i,
    }.freeze

    # Ids of models that are neither chat nor embedding models (images, audio, moderation,
    # reranking, dedicated OCR endpoints). They end up without any capability, so a caller
    # filtering for one skips them instead of offering a model that cannot answer a prompt.
    OTHER_MODEL_ID_PATTERN = %r{
      dall-e | gpt-image | \Asora | \Atts | -tts | whisper | transcribe | audio | realtime
      | moderation | rerank | \Aocr | -ocr | \A(?: babbage | davinci )-
    }xi

    # Ids of embedding models. Only consulted when the provider reports no capabilities, and
    # deliberately narrow: a false positive would hide a chat model from the chat dropdown.
    EMBEDDING_MODEL_ID_PATTERN = %r{
      embed | (?: \A | [/-] ) (?: bge | gte | e5 | minilm | paraphrase )
    }xi

    # Ids of models that accept images. Providers reporting vision themselves never get here.
    VISION_MODEL_ID_PATTERN = %r{
      vision | llava | moondream | minicpm-v | pixtral | gemma3 | -vl[-.:\d]
      | \Agpt-(?: 4o | 4\.1 | 4-turbo | 5 ) | \Ao[34](?: - | \z )
      | \Aclaude-(?: 3 | 4 | 5 | opus | sonnet | haiku )
    }xi

    # A module rather than a `class_methods` block, because the listing is class level throughout
    # (like ping!) and its helpers do not fit into one block.
    module ClassMethods
      def supports_model_listing?
        true
      end

      private

      # The listing request itself, so a provider only has to bring its URL and its
      # authentication. Logged only on error like the other config time requests: the dialog may
      # fetch the list repeatedly, which would otherwise flood the admin HTTP log.
      def model_list_response(url, params: {}, related_object: nil, **)
        UserAgent.get(
          url,
          params,
          {
            **MODEL_LIST_TIMEOUT_OPTIONS,
            verify_ssl: true,
            json:       true,
            log:        log_options(only_on_error: true, related_object:),
            **,
          },
        )
      end

      # A normalized model descriptor. Fields the provider does not report - or reports as
      # something other than the promised type - stay nil instead of being guessed, so a caller
      # can tell "unknown" from a real value.
      #
      # No display name, deliberately: the id is what every consumer renders.
      #
      # @param capabilities [Array<Symbol>, NilClass] as reported by the provider; an empty or
      #   absent list falls back to the id heuristics (e.g. Mistral flags chat and vision, but
      #   leaves an embedding model without any capability at all).
      #
      # @return [Hash] the normalized descriptor
      def model_descriptor(id:, capabilities: nil, embedding_input_limit: nil, embedding_size: nil)
        capabilities = capabilities.presence || capabilities_from_id(id)
        embedding    = capabilities.include?(:embedding)

        {
          id:,
          capabilities:,
          # Both sizes describe an embedding model only, and are reported for one alone: the
          # context window of a chat model has no consumer, and the embedding length Ollama
          # reports for it is merely the hidden size that every model has. What the provider
          # reports wins; the known defaults stand in where it reports nothing.
          embedding_input_limit: (integer_value(embedding_input_limit) || known_embedding_default(:EMBEDDING_INPUT_LIMITS, id) if embedding),
          embedding_size:        (integer_value(embedding_size) || known_embedding_default(:EMBEDDING_SIZES, id) if embedding),
        }
      end

      # Capabilities of a model whose provider reports none, derived from the adapter and the
      # model id.
      #
      # @return [Array<Symbol>] any of :chat, :embedding, :vision - empty for a model that is
      #   neither, and for an embedding model of a provider Zammad cannot embed with.
      def capabilities_from_id(id)
        return [] if id.match?(OTHER_MODEL_ID_PATTERN)

        # Not [:chat] as fallback: an embedding model cannot chat either, so a provider without
        # embedding support (e.g. a custom OpenAI compatible endpoint) has no use for it.
        return supports_embeddings? ? [:embedding] : [] if id.match?(EMBEDDING_MODEL_ID_PATTERN)

        capabilities = [:chat]
        capabilities << :vision if id.match?(VISION_MODEL_ID_PATTERN)
        capabilities
      end

      # The model entries of a listing payload, or nil when it does not have the expected shape.
      # Callers decide whether that is an error or simply no list.
      #
      # @return [Array<Hash>, NilClass] the model entries
      def model_list_entries(data, key = 'data')
        return nil if !data.is_a?(Hash)

        entries = data[key]
        return nil if !entries.is_a?(Array)

        entries.grep(Hash)
      end

      # Strict variant: an endpoint that answers the listing request with anything but a model
      # list is broken, and has to say so rather than render an empty dropdown.
      def model_list_entries!(data, key = 'data')
        entries = model_list_entries(data, key)
        raise AI::Provider::ResponseError, __('The response could not be processed.') if entries.nil?

        entries
      end

      # The normalized, sorted descriptor list for the entries of a listing payload: every entry
      # that carries a usable id under one of `id_keys` is handed to the block, which maps it to a
      # descriptor - so a provider is left with nothing but its own field mapping.
      #
      # @yieldparam entry [Hash] the entry as the provider reported it
      # @yieldparam id [String] its usable id
      #
      # @return [Array<Hash>] the normalized model descriptors
      def normalize_models(entries, *id_keys)
        sort_models(
          entries.filter_map do |entry|
            id = model_id(entry, *id_keys)
            next if id.nil?

            yield(entry, id)
          end
        )
      end

      # The id of a model entry, taken from the first of `keys` that holds a usable one. Anything
      # else is no model to offer: a number or a nested object would otherwise travel through the
      # heuristics (which would raise on it) and into the dropdown as if it were a model name.
      #
      # @return [String, NilClass] the model id
      def model_id(entry, *keys)
        keys.map { |key| entry[key] }.find { |value| string_value(value) }
      end

      # Stable order for the dropdown - the endpoints answer in their own (mostly creation) order.
      def sort_models(models)
        models.sort_by { |model| model[:id].to_s }
      end

      def string_value(value)
        value if value.is_a?(String) && value.present?
      end

      # Only a positive whole number is a size; anything else the provider reports there is not
      # usable - and a provider reporting zero has effectively reported nothing, so the known
      # defaults (or the admin) answer for the model instead of the dialog offering a value its
      # own validation rejects.
      def integer_value(value)
        value if value.is_a?(Integer) && value.positive?
      end
    end
  end
end
