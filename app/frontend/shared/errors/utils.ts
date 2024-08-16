// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import UserError from '#shared/errors/UserError.ts'

import type { ApolloError } from '@apollo/client/core'

export const handleUserErrors = (error: UserError | ApolloError) => {
  if (error instanceof UserError) {
    useNotifications().notify({
      id: error.userErrorId,
      message: error.getFirstErrorMessage(),
      type: NotificationTypes.Error,
    })
  }
}
