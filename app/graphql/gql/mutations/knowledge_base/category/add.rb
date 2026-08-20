# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Category::Add < KnowledgeBase::Base
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Create a knowledge base category.'

    # Not gated with `loads_pundit_method: :update?`: a granular editor of one subtree is usually
    #   only a *reader* of the knowledge base itself, and that must not stand in the way of creating
    #   a category under a category they do have editor access to.
    #
    # Where the new category may be created is decided by CategoryPolicy#create? in the service,
    #   which asks the parent — or the knowledge base for a top level category. The parent in the
    #   input therefore needs no gate of its own.
    argument :knowledge_base_id, GraphQL::Types::ID, loads: Gql::Types::KnowledgeBaseType, description: 'Knowledge base to create the category in.'

    argument :input, Gql::Types::Input::KnowledgeBase::CategoryInputType, description: 'The category data.'

    # Deliberately a flat argument rather than part of `input`, which is the category's *data*: this
    #   is the locale of the call itself — the title in the input is written into it, and the
    #   response is rendered in it. The browse queries take the same flat `locale`. Hence the cop
    #   exemption — folding every argument into one input type would also diverge from every other
    #   mutation here.
    argument :locale, String, description: 'System locale code the submitted title belongs to, and the returned category is localized in.'

    field :category, Gql::Types::KnowledgeBase::CategoryType, null: true, description: 'The created category.'

    def resolve(knowledge_base:, input:, locale:)
      created = Service::KnowledgeBase::Category::Create
        .with_current_user(context.current_user)
        .execute(
          knowledge_base:,
          category_data:  input.to_h,
          # Also stores the locale the payload is rendered in: its locale-dependent fields go
          #   straight into the client cache, so they must speak the locale that was written.
          kb_locale:      use_knowledge_base_locale!(knowledge_base, locale),
        )

      { category: created }
    rescue Exceptions::UnprocessableContent => e
      error_response({ message: e.message })
    rescue Exceptions::InvalidAttribute => e
      error_response({ message: e.message, field: e.attribute })
    end
  end
end
