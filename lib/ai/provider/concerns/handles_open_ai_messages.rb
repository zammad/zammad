# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Provider
  module Concerns::HandlesOpenAIMessages
    extend ActiveSupport::Concern

    included do
      def messages_for(prompt_system:, prompt_user:, prompt_image:)
        messages = []

        if prompt_system.present?
          messages.push({
                          role:    'system',
                          content: prompt_system,
                        })
        end

        messages.push({
                        role:    'user',
                        content: content_for(prompt_user:, prompt_image:),
                      })

        messages
      end
    end

    private

    def content_for(prompt_user:, prompt_image:)
      return prompt_user if !prompt_image.is_a?(::Store)

      # https://platform.openai.com/docs/guides/vision-fine-tuning#data-format
      [
        {
          type: 'text',
          text: prompt_user,
        },
        {
          type:      'image_url',
          image_url: {
            url: "data:#{prompt_image.preferences['Content-Type'].to_s.split(';').first.strip};base64,#{Base64.strict_encode64(prompt_image.content_ocr)}",
          },
        },
      ]
    end
  end
end
