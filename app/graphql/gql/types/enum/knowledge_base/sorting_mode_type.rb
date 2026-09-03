# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum::KnowledgeBase
  # Built from KnowledgeBase::SORTING_MODES — the very constant both models validate against, so a
  #   mode the schema accepts is always one a node can store, and adding one there reaches the
  #   clients without a second edit here. What each mode orders by is documented on that constant.
  #
  # Hence no per-value descriptions, unlike Gql::Types::Enum::KnowledgeBase::VisibilityType: the
  #   picker labels the modes with its own translated strings anyway, and a hand-written list here
  #   could drift from the models. The same trade-off Gql::Types::Enum::PublicLinksScreenType makes.
  class SortingModeType < Gql::Types::Enum::BaseEnum
    description 'How the content of a knowledge base node — its root or a single category — is ordered when browsed'

    build_string_list_enum ::KnowledgeBase::SORTING_MODES
  end
end
