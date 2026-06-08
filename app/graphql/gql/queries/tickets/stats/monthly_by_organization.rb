# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Tickets::Stats::MonthlyByOrganization < Tickets::Stats::BaseMonthly

    description 'Fetch monthly ticket stats by organization'

    argument :organization_id, GraphQL::Types::ID, description: 'Organization to generate stats for', loads: Gql::Types::OrganizationType

    def resolve(organization:)
      resolve_stats(conditions: { 'tickets.organization_id' => organization.id })
    end
  end
end
