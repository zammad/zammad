# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Category::Update < KnowledgeBase::Base
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Update a knowledge base category.'

    argument :category_id, GraphQL::Types::ID, loads: Gql::Types::KnowledgeBase::CategoryType, loads_pundit_method: :update?, description: 'Category to update.'

    # The parent rides inside the input, deliberately ungated there: the form sends the stored parent
    #   back on every save, and a granular editor's stored parent may well be one they have no editor
    #   access to — renaming such a category has to stay possible. Only an actual move is authorized
    #   against the target, which the service does.
    argument :input, Gql::Types::Input::KnowledgeBase::CategoryInputType, description: 'The category data.'

    # Deliberately a flat argument rather than part of `input`, which is the category's *data*: this
    #   is the locale of the call itself — the title in the input is written into it, and the
    #   response is rendered in it. The browse queries take the same flat `locale`. Hence the cop
    #   exemption — folding every argument into one input type would also diverge from every other
    #   mutation here.
    argument :locale, String, description: 'System locale code the submitted title belongs to, and the returned category is localized in.'

    field :category, Gql::Types::KnowledgeBase::CategoryType, null: true, description: 'The updated category.'

    def resolve(category:, input:, locale:)
      updated = Service::KnowledgeBase::Category::Update
        .with_current_user(context.current_user)
        .execute(
          category:,
          category_data: input.to_h,
          # Also stores the locale the payload is rendered in. It carries locale-dependent fields
          #   (title, visibility, breadcrumb titles), which the client normalizes straight into its
          #   cache — so they have to come back in the locale that was written, not in the primary one.
          kb_locale:     use_knowledge_base_locale!(category.knowledge_base, locale),
        )

      { category: updated }
    rescue Exceptions::UnprocessableContent => e
      error_response({ message: e.message })
    rescue Exceptions::InvalidAttribute => e
      error_response({ message: e.message, field: e.attribute })
    end
  end
end
