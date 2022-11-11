// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

export interface CommonStepperStep {
  label: string
  order: number
  errorCount: number
  valid: boolean
  disabled: boolean
  completed: boolean
}
