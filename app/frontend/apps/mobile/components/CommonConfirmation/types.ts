// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

export interface ConfirmationOptions {
  heading: string
  headingPlaceholder?: string[]
  buttonTitle?: string
  buttonTextColorClass?: string
  confirmCallback: () => void
  cancelCallback?: () => void
}
