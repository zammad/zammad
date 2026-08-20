# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::KnowledgeBase
  class CategoryInputType < Gql::Types::BaseInputObject
    description 'Represents the knowledge base category attributes to be used in create and update.'

    # Every attribute is optional so one type can serve both mutations: an update only sends what
    #   changed, and what a *create* additionally requires is enforced where the record is built
    #   (Service::KnowledgeBase::Category::Create), not by the schema.
    argument :category_icon, String, required: false, description: 'Icon of the category, from the icon set of its knowledge base. Defaults to the knowledge base default icon on create.'

    # Omitting it leaves the category where it is (or creates it at the top level), an explicit
    #   `null` moves it to the top level — both cases exist, so the write path goes by whether the
    #   argument was submitted at all rather than by its value.
    #
    # Not gated with `loads_pundit_method:` here: only *creating* under a parent needs access to it,
    #   and the update mutation must keep working for a granular editor whose stored parent is
    #   reader-only for them (see there). The add mutation authorizes it for itself.
    argument :parent_id, GraphQL::Types::ID, required: false, loads: Gql::Types::KnowledgeBase::CategoryType, description: 'Category this category belongs under. Pass `null` for the top level, omit it to leave the parent unchanged.'

    # A category has no title column: it has one title per knowledge base locale, and the mutation's
    #   `locale` says which one this is. Omitting it keeps the stored titles as they are — including
    #   the one of that very locale.
    argument :title, Gql::Types::NonEmptyStringType, required: false, description: 'Title of the category in the locale of this mutation.'

    argument :permissions, [Gql::Types::Input::KnowledgeBase::RolePermissionInputType], required: false, description: 'Granular access per role, applied in the same transaction as the category itself. Omitted leaves the stored permissions alone, an empty list drops all of them (everything is then inherited).'
  end
end
