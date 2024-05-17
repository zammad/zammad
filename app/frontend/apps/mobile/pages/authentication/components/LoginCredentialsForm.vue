<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'

import { useNotifications } from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useForceDesktop } from '#shared/composables/useForceDesktop.ts'
import type { LoginCredentials } from '#shared/entities/two-factor/types.ts'
import UserError from '#shared/errors/UserError.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import type { UserLoginTwoFactorMethods } from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import { ensureAfterAuth } from '../after-auth/composable/useAfterAuthPlugins.ts'

const emit = defineEmits<{
  error: [UserError]
  finish: []
  askTwoFactor: [
    twoFactor: Required<UserLoginTwoFactorMethods>,
    formData: FormSubmitData<LoginCredentials>,
  ]
}>()

const application = useApplicationStore()
const { forceDesktop } = useForceDesktop()

const loginSchema = defineFormSchema([
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        name: 'login',
        type: 'text',
        label: __('Username / Email'),
        placeholder: __('Username / Email'),
        required: true,
      },
    ],
  },
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        name: 'password',
        label: __('Password'),
        placeholder: __('Password'),
        type: 'password',
        required: true,
      },
    ],
  },
  {
    isLayout: true,
    element: 'div',
    attrs: {
      class: 'mt-2.5 flex grow items-center justify-between text-white',
    },
    children: [
      {
        type: 'checkbox',
        name: 'rememberMe',
        label: __('Remember me'),
        wrapperClass: '!h-6',
      },
      // TODO support if/then in form-schema
      ...(application.config.user_lost_password
        ? [
            {
              isLayout: true,
              component: 'CommonLink',
              props: {
                class: 'text-right text-white',
                link: '/#password_reset',
                onClick: forceDesktop,
              },
              children: __('Forgot password?'),
            },
          ]
        : []),
    ],
  },
])

const { form, isDisabled } = useForm()

const { clearAllNotifications } = useNotifications()

const authentication = useAuthenticationStore()
const router = useRouter()

const sendCredentials = (formData: FormSubmitData<LoginCredentials>) => {
  // Clear notifications to avoid duplicated error messages.
  clearAllNotifications()

  return authentication
    .login(formData)
    .then(({ twoFactor, afterAuth }) => {
      if (afterAuth) {
        return ensureAfterAuth(router, afterAuth)
      }

      if (!twoFactor || !twoFactor.defaultTwoFactorAuthenticationMethod) {
        emit('finish')
      } else {
        emit(
          'askTwoFactor',
          twoFactor as Required<UserLoginTwoFactorMethods>,
          formData,
        )
      }
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
    id="signin"
    ref="form"
    class="text-left"
    :schema="loginSchema"
    @submit="sendCredentials($event as FormSubmitData<LoginCredentials>)"
  >
    <template #after-fields>
      <div
        v-if="$c.user_create_account"
        class="mt-4 flex grow items-center justify-center"
      >
        <span class="ltr:mr-1 rtl:ml-1">{{ $t('New user?') }}</span>
        <CommonLink
          link="/#signup"
          class="!text-yellow cursor-pointer select-none underline"
          @click="forceDesktop"
        >
          {{ $t('Register') }}
        </CommonLink>
      </div>
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
