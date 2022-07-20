// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

export interface ConfirmationOptions {
  heading: string
  buttonTitle?: string
  buttonTextColorClass?: string
  confirmCallback: () => void
  cancelCallback?: () => void
}
