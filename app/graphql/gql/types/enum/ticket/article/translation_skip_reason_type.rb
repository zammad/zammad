# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class Ticket::Article::TranslationSkipReasonType < BaseEnum
    description 'Why translating a whole ticket left an article in its original language'

    value 'excluded_language', 'The article is in a language the agent reads in the original'
  end
end
