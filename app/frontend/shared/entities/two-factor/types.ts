// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { EnumTwoFactorMethod } from '#shared/graphql/types.ts'
import type { AppSpecificRecord } from '#shared/types/app.ts'

export interface TwoFactorPlugin {
  name: EnumTwoFactorMethod
  label: string
  order: number
  icon: AppSpecificRecord<string>
  helpMessage?: string
}
