// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

export type SecurityOption = 'encryption' | 'sign'
export type SecurityValue = SecurityOption[] | null | undefined
export type SecurityAllowed = SecurityOption[]
export type SecurityMessage = {
  message: string
  messagePlaceholder?: string[]
}
export type SecurityMessages = Record<SecurityOption, SecurityMessage>
