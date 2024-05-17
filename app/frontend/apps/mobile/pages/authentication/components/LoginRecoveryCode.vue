<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useNotifications } from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import type {
  FormSubmitData,
  FormSchemaNode,
} from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import type {
  LoginCredentials,
  RecoveryCodeFormData,
} from '#shared/entities/two-factor/types.ts'
import UserError from '#shared/errors/UserError.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'

const props = defineProps<{
  credentials: LoginCredentials
}>()

const emit = defineEmits<{
  finish: []
  error: [UserError]
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

const enterRecoveryCode = (formData: FormSubmitData<RecoveryCodeFormData>) => {
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
    @submit="enterRecoveryCode($event as FormSubmitData<RecoveryCodeFormData>)"
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
