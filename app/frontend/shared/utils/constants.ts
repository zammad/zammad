// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

export const SYSTEM_USER_INTERNAL_ID = 1
export const SYSTEM_USER_ID = convertToGraphQLId(
  'User',
  SYSTEM_USER_INTERNAL_ID,
)
