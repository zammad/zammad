<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import Form from '#shared/components/Form/Form.vue'
import type {
  FormSubmitData,
  FormSchemaNode,
} from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import type {
  RecoveryCodeFormData,
  LoginCredentials,
} from '#shared/entities/two-factor/types.ts'
import UserError from '#shared/errors/UserError.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

const props = defineProps<{
  credentials: LoginCredentials
}>()

const emit = defineEmits<{
  finish: []
  error: [error: UserError]
  'clear-error': []
}>()

const schema: FormSchemaNode[] = [
  {
    type: 'text',
    name: 'code',
    label: __('Recovery Code'),
    required: true,
    props: {
      help: __('Enter one of your unused recovery codes.'),
    },
  },
]

const authentication = useAuthenticationStore()
const { form, isDisabled } = useForm()

const enterRecoveryCode = (formData: FormSubmitData<RecoveryCodeFormData>) => {
  // Clear notifications to avoid duplicated error messages.
  emit('clear-error')

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
    @submit="enterRecoveryCode($event as FormSubmitData<RecoveryCodeFormData>)"
  >
    <template #after-fields>
      <CommonButton
        type="submit"
        variant="submit"
        size="large"
        class="mt-8"
        block
        :disabled="isDisabled"
      >
        {{ $t('Sign in') }}
      </CommonButton>
    </template>
  </Form>
</template>
