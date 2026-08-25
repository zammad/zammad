# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Category::Add < KnowledgeBase::Base
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Create a knowledge base category.'

    argument :input, Gql::Types::Input::KnowledgeBase::CategoryInputType, description: 'The category data.'

    # Deliberately a flat argument rather than part of `input`, which is the category's *data*: this
    #   is the locale of the call itself — the title in the input is written into it, and the
    #   response is rendered in it. The browse queries take the same flat `locale`. Hence the cop
    #   exemption — folding every argument into one input type would also diverge from every other
    #   mutation here.
    argument :locale, String, description: 'System locale code the submitted title belongs to, and the returned category is localized in.'

    field :category, Gql::Types::KnowledgeBase::CategoryType, null: true, description: 'The created category.'

    # Where the new category may be created is decided by CategoryPolicy#create? in the service,
    #   which asks the parent — or the knowledge base for a top level category. Neither the
    #   knowledge base nor the parent in the input is gated here: a granular editor of one subtree is
    #   usually only a *reader* of the knowledge base itself, and that must not stand in the way of
    #   creating a category under a category they do have editor access to.
    def resolve(input:, locale:)
      created = Service::KnowledgeBase::Category::Create
        .with_current_user(context.current_user)
        .execute(category_data: input.to_h, kb_locale: locale)

      # The locale the payload is rendered in, which the service just wrote the title into: its
      #   locale-dependent fields go straight into the client cache, so they must speak the locale
      #   that was written. The service rejects a locale the knowledge base does not have, so this
      #   resolves to that very locale.
      store_knowledge_base_locale(created.knowledge_base, locale)

      { category: created }
    rescue Exceptions::UnprocessableContent => e
      error_response({ message: e.message })
    rescue Exceptions::InvalidAttribute => e
      error_response({ message: e.message, field: e.attribute })
    end
  end
end
