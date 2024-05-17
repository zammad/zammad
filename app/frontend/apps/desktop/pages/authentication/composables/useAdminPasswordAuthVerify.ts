// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'

import type { AlertVariant } from '#shared/components/CommonAlert/types.ts'
import type {
  FormSchemaField,
  FormValues,
} from '#shared/components/Form/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import { useAdminPasswordAuthVerifyMutation } from '../graphql/mutations/adminPasswordAuthVerify.api.ts'

interface AdminPasswordAuthVerifyOptions {
  formChangeFields: Record<string, Partial<FormSchemaField>>
  formInitialValues: FormValues
}

export const useAdminPasswordAuthVerify = (
  options: AdminPasswordAuthVerifyOptions,
) => {
  const route = useRoute()

  const token = route.query.token as string

  if (!token) return {}

  const verifyToken = new MutationHandler(
    useAdminPasswordAuthVerifyMutation({
      variables: { token },
    }),
    {
      errorShowNotification: false,
    },
  )

  const verifyTokenResult = ref(false)
  const verifyTokenMessage = ref('')

  verifyToken
    .send()
    .then((data) => {
      if (data?.adminPasswordAuthVerify?.login) {
        options.formChangeFields.login = {
          props: {
            disabled: true,
          },
        }

        options.formInitialValues.login = data.adminPasswordAuthVerify.login

        verifyTokenMessage.value = __(
          'The token is valid. You are now able to login via password once.',
        )

        verifyTokenResult.value = true
      }
    })
    .catch(() => {
      verifyTokenMessage.value = __(
        'The token for the admin password login is invalid.',
      )
    })

  const verifyTokenAlertVariant = computed<AlertVariant>(() => {
    return verifyTokenResult.value ? 'success' : 'danger'
  })

  return {
    verifyTokenResult,
    verifyTokenMessage,
    verifyTokenAlertVariant,
  }
}
