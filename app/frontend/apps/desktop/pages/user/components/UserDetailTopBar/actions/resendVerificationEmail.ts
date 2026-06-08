// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import type { User } from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import { useUserSignupResendMutation } from '#desktop/entities/user/graphql/mutations/userSignupResend.api.ts'
import type { DetailViewActionPlugin } from '#desktop/types/actions.ts'

export default <DetailViewActionPlugin>{
  key: 'resend-verification-email',
  label: __('Resend verification email'),
  icon: 'envelope',
  order: 400,
  permission: ['ticket.agent', 'admin.user'],
  show: (user: User) => !user.verified && user.source === 'signup' && user.email,
  onClick: (user: User) => {
    if (!user.email) return

    const { notify } = useNotifications()

    const resendVerifyEmail = new MutationHandler(
      useUserSignupResendMutation({
        variables: {
          email: user.email,
        },
      }),
      {
        errorShowNotification: false,
      },
    )

    resendVerifyEmail
      .send()
      .then(() => {
        notify({
          id: 'resend-verify-email',
          type: NotificationTypes.Success,
          message: __('Email sent to "%s". Please let the user verify their email account.'),
          messagePlaceholder: [user.email!],
        })
      })
      .catch(() => {
        notify({
          id: 'resend-verify-email-error',
          type: NotificationTypes.Error,
          message: __('Failed to send email to "%s". Please contact an administrator.'),
          messagePlaceholder: [user.email!],
        })
      })
  },
}
