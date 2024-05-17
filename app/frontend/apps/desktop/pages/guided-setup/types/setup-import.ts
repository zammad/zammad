// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormRef } from '#shared/components/Form/types.ts'

import type { ShallowRef, Ref } from 'vue'

export interface ImportSource {
  form: ShallowRef<FormRef | undefined>
  loading: Ref<boolean>
  debouncedLoading: Readonly<Ref<boolean>>
  onContinueButtonCallback: Ref<(() => void) | undefined>
}

export interface ImportSourceConfigurationBase {
  url: string
  username?: string
  secret?: string
  sslVerify?: boolean
}

export interface ImportSourceConfigurationFreshdeskData
  extends ImportSourceConfigurationBase {
  secret: string
}

export interface ImportSourceConfigurationZendeskData
  extends ImportSourceConfigurationBase {
  username: string
  secret: string
}

export interface ImportSourceConfigurationKayakoData
  extends ImportSourceConfigurationBase {
  username: string
  secret: string
}

export interface ImportSourceConfigurationOtrsData
  extends ImportSourceConfigurationBase {
  sslVerify: boolean
}

export interface ImportSourceStatusProgressItem {
  entity: string
  entityLabel: string
  processed?: string
  total?: string
  isFinished: boolean
}
