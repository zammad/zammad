// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { EnumSecurityStateType } from '#shared/graphql/types.ts'

export { EnumSecurityStateType } from '#shared/graphql/types.ts'

export type SecurityOption = 'encryption' | 'sign'
export type SecurityAllowed = Record<EnumSecurityStateType, SecurityOption[]>
export type SecurityValue =
  | { method: EnumSecurityStateType; options: SecurityOption[] }
  | null
  | undefined
export type SecurityMessage = {
  message: string
  messagePlaceholder?: string[]
}
export type SecurityMessages = Record<
  EnumSecurityStateType,
  Record<SecurityOption, SecurityMessage>
>
