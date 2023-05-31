<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormData, FormSchemaNode } from '#shared/components/Form/types.ts'
import type { TwoFactorPlugin } from '#shared/entities/two-factor/types.ts'
import UserError from '#shared/errors/UserError.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import { computed } from 'vue'
import type { LoginFormData, TwoFactorFormData } from '../types/login.ts'

const props = defineProps<{
  credentials: FormData<LoginFormData>
  twoFactor: TwoFactorPlugin
}>()

const emit = defineEmits<{
  (e: 'finish'): void
  (e: 'error', error: UserError): void
}>()

// TODO: this should be configurable by two factor plugin
const schema: FormSchemaNode[] = [
  {
    isLayout: true,
    component: 'FormGroup',
    props: {
      help: computed(() => props.twoFactor.helpMessage),
    },
    children: [
      {
        type: 'text',
        name: 'code',
        label: __('Security Code'),
        required: true,
        props: {
          autocomplete: 'one-time-code',
          autofocus: true,
          inputmode: 'numeric',
          pattern: '[0-9]*',
        },
      },
    ],
  },
]

const { clearAllNotifications } = useNotifications()
const authentication = useAuthenticationStore()

const confirmTwoFactor = (formData: FormData<TwoFactorFormData>) => {
  // Clear notifications to avoid duplicated error messages.
  clearAllNotifications()
  const { login, password, rememberMe } = props.credentials

  return authentication
    .login(login, password, rememberMe, {
      payload: formData.code,
      method: props.twoFactor.name,
    })
    .then(() => {
      emit('finish')
    })
    .catch((error: UserError) => {
      if (error instanceof UserError) {
        emit('error', error)
      }
    })
}
</script>

<template>
  <Form
    :schema="schema"
    @submit="confirmTwoFactor($event as FormData<TwoFactorFormData>)"
  >
    <template #after-fields>
      <FormKit
        wrapper-class="mt-6 flex grow justify-center items-center"
        input-class="py-2 px-4 w-full h-14 text-xl rounded-xl select-none"
        variant="submit"
        type="submit"
      >
        {{ $t('Sign in') }}
      </FormKit>
    </template>
  </Form>
</template>
