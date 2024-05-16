// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  EnumNotificationSoundFile,
  type UserPersonalSettingsNotificationMatrix,
} from '#shared/graphql/types.ts'

export interface NotificationFormData {
  group_ids: number[]
  file: EnumNotificationSoundFile
  enabled: boolean
  matrix: UserPersonalSettingsNotificationMatrix
}
