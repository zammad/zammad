// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  EnumSystemSetupInfoStatus,
  EnumSystemSetupInfoType,
} from '#shared/graphql/types.ts'

export interface SystemSetupInfoStorage {
  type?: EnumSystemSetupInfoType | null
  status?: EnumSystemSetupInfoStatus
  lockValue?: string
  importSource?: string
}
