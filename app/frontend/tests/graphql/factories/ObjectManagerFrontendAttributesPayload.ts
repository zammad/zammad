// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  EnumObjectManagerObjects,
  type ObjectManagerFrontendAttributesPayload,
} from '#shared/graphql/types.ts'

import organizationAttributes from './fixtures/organization-object-attributes.ts'
import ticketAtricleAttributes from './fixtures/ticket-article-object-attributes.ts'
import ticketAttributes from './fixtures/ticket-object-attributes.ts'
import userAttributes from './fixtures/user-object-attributes.ts'

import type { ResolversMeta } from '../builders/index.ts'

const payloads: Record<
  EnumObjectManagerObjects,
  () => ObjectManagerFrontendAttributesPayload
> = {
  [EnumObjectManagerObjects.Group]: () => ({ screens: [], attributes: [] }),
  [EnumObjectManagerObjects.User]: userAttributes,
  [EnumObjectManagerObjects.Organization]: organizationAttributes,
  [EnumObjectManagerObjects.Ticket]: ticketAttributes,
  [EnumObjectManagerObjects.TicketArticle]: ticketAtricleAttributes,
}

export default (
  _1: unknown,
  _2: unknown,
  meta: ResolversMeta,
): ObjectManagerFrontendAttributesPayload => {
  return payloads[meta.variables.object as EnumObjectManagerObjects]()
}
