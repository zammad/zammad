# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Answer::Translation
  module Search
    extend ActiveSupport::Concern

    include CanSelector
    include CanSearch

    included do
      scope :search_sql_extension, lambda { |params|
        return if params[:current_user]&.permissions?('knowledge_base.editor')

        answer_ids = KnowledgeBase::Answer.internal.pluck(:id)

        where(answer_id: answer_ids)
      }

      scope :search_sql_query_extension, lambda { |params|
        return if params[:query].blank?

        search_sql_text_fallback(params[:query])
      }
    end

    class_methods do
      def search_preferences(current_user)
        return false if !KnowledgeBase.exists? || !current_user.permissions?('knowledge_base.*')

        {
          prio:                1209,
          direct_search_index: false,
        }
      end

      def search_query_extension(params)
        kb_locales = KnowledgeBase.active.map { |elem| KnowledgeBase::Locale.preferred(params[:current_user], elem) }

        output = { bool: { filter: { terms: { kb_locale_id: kb_locales.map(&:id) } } } }

        return output if params[:current_user]&.permissions?('knowledge_base.editor')

        output[:bool][:must] = [ { terms: {
          answer_id: KnowledgeBase::Answer.internal.pluck(:id)
        } } ]

        output
      end
    end
  end
end
