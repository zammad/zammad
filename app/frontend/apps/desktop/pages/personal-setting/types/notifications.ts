// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormValues } from '#shared/components/Form/types.ts'
import {
  EnumNotificationSoundFile,
  type UserPersonalSettingsNotificationMatrix,
} from '#shared/graphql/types.ts'

export interface NotificationFormData extends FormValues {
  group_ids: number[]
  file: EnumNotificationSoundFile
  enabled: boolean
  matrix: UserPersonalSettingsNotificationMatrix
}
