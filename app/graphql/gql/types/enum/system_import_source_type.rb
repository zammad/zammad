# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class SystemImportSourceType < BaseEnum
    description 'Third-party system source'

    build_string_list_enum %w[freshdesk kayako otrs zendesk].freeze
  end
end
