<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useNotifications } from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import { useForm } from '#shared/components/Form/composable.ts'
import type { FormData, FormSchemaNode } from '#shared/components/Form/types.ts'
import UserError from '#shared/errors/UserError.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import type { LoginFormData, RecoveryCodeFormData } from '../types/login.ts'

const props = defineProps<{
  credentials: FormData<LoginFormData>
}>()

const emit = defineEmits<{
  (e: 'finish'): void
  (e: 'error', error: UserError): void
}>()

const schema: FormSchemaNode[] = [
  {
    isLayout: true,
    component: 'FormGroup',
    props: {
      help: __('Enter one of your unused recovery codes.'),
    },
    children: [
      {
        type: 'text',
        name: 'code',
        label: __('Recovery Code'),
        required: true,
      },
    ],
  },
]

const { clearAllNotifications } = useNotifications()
const authentication = useAuthenticationStore()
const { form, isDisabled } = useForm()

const enterRecoveryCode = (formData: FormData<RecoveryCodeFormData>) => {
  // Clear notifications to avoid duplicated error messages.
  clearAllNotifications()
  const { login, password, rememberMe } = props.credentials

  return authentication
    .login({
      login,
      password,
      rememberMe,
      recoveryCode: formData.code,
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
    ref="form"
    :schema="schema"
    @submit="enterRecoveryCode($event as FormData<RecoveryCodeFormData>)"
  >
    <template #after-fields>
      <FormKit
        wrapper-class="mt-6 flex grow justify-center items-center"
        input-class="py-2 px-4 w-full h-14 text-xl rounded-xl select-none"
        variant="submit"
        type="submit"
        :disabled="isDisabled"
      >
        {{ $t('Sign in') }}
      </FormKit>
    </template>
  </Form>
</template>
