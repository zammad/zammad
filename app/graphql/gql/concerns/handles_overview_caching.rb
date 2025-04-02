# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Concerns::HandlesOverviewCaching
  extend ActiveSupport::Concern

  included do

    def object_cache_key(overview)
      # context_key seems to only work in field resolvers, so build a custom cache key here.
      # query_cache_key of graphql-fragment_cache already has all arguments and selected fields covered,
      #   so here we only need to cover the additional dynamic parts.
      cache_key_parts = [
        "overviewLastUpdate:#{overview.updated_at.to_time.to_i}",
        "groupPermissions:#{context.current_user.group_ids_access(:overview).sort}",
      ]

      # Cache overview contents by permission set by default, so that users with same permissions use the same cache.
      # Only include the currentUserId for overviews which refer to the current user.
      cache_key_parts << "currentUserId:#{context.current_user.id}" if overview_is_personalized?(overview)

      cache_key_parts.join('-')
    end

    def overview_is_personalized?(overview)
      # Stringify so that it works both with simple and expert mode conditions.
      overview.condition.to_s.include?('current_user')
    end

  end
end
