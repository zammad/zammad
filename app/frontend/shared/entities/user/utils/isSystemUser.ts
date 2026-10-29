// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { SYSTEM_USER_ID } from '#shared/utils/constants.ts'

export const isSystemUserId = (id?: Maybe<string>) => id === SYSTEM_USER_ID

// The system account stands in for a ticket without a customer or an owner.
export const isSystemUser = (user?: Maybe<{ id: string }>) => isSystemUserId(user?.id)
