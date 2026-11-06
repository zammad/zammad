# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The parameters of the tools that write a message, declared once: the format of its text, as the REST API takes an
#   article, and the time the user spent on it, which the user may also skip, as in Zammad's own time accounting.
module Service::AI::Tool::Concerns::ArticleParameters
  extend ActiveSupport::Concern

  class_methods do
    # Written for the model, like every text a tool returns, so not translated.
    # rubocop:disable Zammad/DetectTranslatableString

    # @param channels [Boolean] whether the message may go out over a channel, which takes plain text only
    def content_type_parameter(channels: false)
      parameter :content_type, type: :string, enum: Service::AI::Tool::CreateArticle::Preparation::CONTENT_TYPES, default: 'text/plain',
                               description: 'The format of text. text/html for headings, lists, tables or links; Zammad removes unsafe markup.' \
                                            "#{' SMS, Telegram, WhatsApp and Facebook take text/plain only.' if channels}"
    end

    def time_unit_parameter
      parameter :time_unit, type: :number, description: 'The time the user says they spent, where Zammad accounts time; never an estimate.'
      parameter :skip_time_accounting, type: :boolean, description: 'true once the user said they account no time for this message, as Zammad\'s Skip does. Never on your own.'
    end

    # rubocop:enable Zammad/DetectTranslatableString
  end
end
