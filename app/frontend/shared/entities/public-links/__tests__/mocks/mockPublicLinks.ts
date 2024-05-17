// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '#tests/support/mock-graphql-api.ts'

import type { PublicLinksQuery } from '#shared/graphql/types.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

import { PublicLinksDocument } from '../../graphql/queries/links.api.ts'
import { PublicLinkUpdatesDocument } from '../../graphql/subscriptions/currentLinks.api.ts'

export const mockPublicLinksSubscription = () => {
  return mockGraphQLSubscription(PublicLinkUpdatesDocument)
}

export const mockPublicLinks = (
  publicLinks: ConfidentTake<PublicLinksQuery, 'publicLinks'> = [],
) => {
  return mockGraphQLApi(PublicLinksDocument).willResolve({
    publicLinks,
  })
}
