// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'

import type { TwoFactorConfigurationActionPayload } from '#desktop/components/TwoFactor/types.ts'

export const usePasswordCheckTwoFactor = (
  formSubmitCallback?: (payload: TwoFactorConfigurationActionPayload) => void,
) => {
  const redirectToPasswordCheck = () => {
    useNotifications().notify({
      id: 'two-factor-invalid-password-revalidation-token',
      type: NotificationTypes.Error,
      message: __(
        'Invalid password revalidation token, please confirm your password again.',
      ),
    })

    formSubmitCallback?.({ nextState: 'password_check' })
  }

  return {
    redirectToPasswordCheck,
  }
}
