# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Answer::Translation
  module Search
    extend ActiveSupport::Concern

    include CanSelector
    include CanSearch

    included do
      scope :search_sql_extension, lambda { |params|
        return if params[:current_user]&.permissions?('knowledge_base.editor')

        where(answer_id: search_answer_ids_for_user(params[:current_user]))
      }

      scope :search_sql_query_extension, lambda { |params|
        query = params[:query]&.delete('*')
        return if query.blank?

        search_sql_text_fallback(query)
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
          answer_id: search_answer_ids_for_user(params[:current_user])
        } } ]

        output
      end

      def search_answer_ids_for_user(user)
        KnowledgeBase::Answer.visible_to_user(user).pluck(:id)
      end
    end
  end
end
