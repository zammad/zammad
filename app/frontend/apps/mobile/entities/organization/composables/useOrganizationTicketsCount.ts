// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketCount } from '@shared/graphql/types'

interface RequiredOrganization {
  id: string
  internalId: number
  name?: Maybe<string>
  ticketsCount?: Maybe<TicketCount>
}

export const useOrganizationTicketsCount = () => {
  const getTicketData = (organization?: Maybe<RequiredOrganization>) => {
    if (!organization || !organization.ticketsCount) return null
    return {
      count: organization.ticketsCount,
      createLabel: __('Create new ticket for this organization'),
      createLink: `/tickets/create?organization_id=${organization.internalId}`,
      query: `organization.id: ${organization.internalId}`,
    }
  }

  return { getTicketData }
}
