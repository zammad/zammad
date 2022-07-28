<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRoute, useRouter } from 'vue-router'
import {
  useNotifications,
  NotificationTypes,
} from '@shared/components/CommonNotifications'
import useAuthenticationStore from '@shared/stores/authentication'
import CommonLogo from '@shared/components/CommonLogo/CommonLogo.vue'
import Form from '@shared/components/Form/Form.vue'
import { type FormData, useForm } from '@shared/components/Form'
import UserError from '@shared/errors/UserError'
import { defineFormSchema } from '@mobile/form/composable'
import useApplicationLoadedStore from '@shared/stores/application'

interface Props {
  invalidatedSession?: string
}

const props = defineProps<Props>()

// Output a hint when the session is no longer valid.
// This could happen because the session was deleted on the server.
if (props.invalidatedSession === '1') {
  const { notify } = useNotifications()

  notify({
    message: __('The session is no longer valid. Please log in again.'),
    type: NotificationTypes.Warn,
  })
}

const authentication = useAuthenticationStore()

const router = useRouter()
const route = useRoute()

const application = useApplicationLoadedStore()

const loginScheme = defineFormSchema([
  {
    name: 'login',
    type: 'text',
    label: __('Username / Email'),
    placeholder: __('Username / Email'),
    required: true,
    outerClass: 'mb-2',
    wrapperClass: 'rounded-xl bg-gray-500',
  },
  {
    name: 'password',
    label: __('Password'),
    placeholder: __('Password'),
    type: 'password',
    required: true,
    outerClass: 'mb-2',
    wrapperClass: 'rounded-xl bg-gray-500',
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
              },
              children: __('Forgot password?'),
            },
          ]
        : []),
    ],
  },
])

interface LoginFormData {
  login?: string
  password?: string
  rememberMe?: boolean
}

// TODO: workaround for disabled button state, will be changed in formkit.
const { form, isDisabled } = useForm()

const login = (formData: FormData<LoginFormData>) => {
  const { notify, clearAllNotifications } = useNotifications()

  // Clear notifications to avoid duplicated error messages.
  clearAllNotifications()

  return authentication
    .login(formData.login!, formData.password!, formData.rememberMe!)
    .then(() => {
      // TODO: maybe we need some additional logic for the ThirtParty-Login situtation.
      const { redirect: redirectUrl } = route.query
      if (typeof redirectUrl === 'string') {
        router.replace(redirectUrl)
      } else {
        router.replace('/')
      }
    })
    .catch((errors: UserError) => {
      if (errors instanceof UserError) {
        notify({
          message: errors.generalErrors[0],
          type: NotificationTypes.Error,
        })
      }
    })
}
</script>

<template>
  <!-- TODO: Only a "second" dummy implementation for the login... -->
  <div class="flex h-full min-h-screen flex-col items-center px-6 pt-6 pb-4">
    <div class="m-auto w-full max-w-md">
      <div class="flex grow flex-col justify-center">
        <div class="my-5 grow">
          <div class="flex justify-center p-2">
            <CommonLogo />
          </div>
          <div class="mb-6 flex justify-center p-2 text-2xl font-extrabold">
            {{ $c.product_name }}
          </div>
          <template v-if="$c.maintenance_mode">
            <div
              class="my-1 flex items-center rounded-xl bg-red py-2 px-4 text-white"
            >
              {{
                $t(
                  'Zammad is currently in maintenance mode. Only administrators can log in. Please wait until the maintenance window is over.',
                )
              }}
            </div>
          </template>
          <template v-if="$c.maintenance_login && $c.maintenance_login_message">
            <!-- eslint-disable vue/no-v-html -->
            <div
              class="my-1 flex items-center rounded-xl bg-green py-2 px-4 text-white"
              v-html="$c.maintenance_login_message"
            ></div>
          </template>
          <Form
            id="login"
            ref="form"
            class="text-left"
            :schema="loginScheme"
            @submit="login"
          >
            <template #after-fields>
              <div
                v-if="$c.user_create_account"
                class="mt-4 flex grow items-center justify-center"
              >
                <span class="ltr:mr-1 rtl:ml-1">{{ $t('New user?') }}</span>
                <CommonLink
                  link="/#signup"
                  class="cursor-pointer select-none !text-yellow underline"
                >
                  {{ $t('Register') }}
                </CommonLink>
              </div>
              <FormKit
                wrapper-class="mt-4 flex grow justify-center items-center"
                input-class="py-2 px-4 w-full h-14 text-xl font-semibold text-black formkit-variant-primary:bg-yellow rounded-xl select-none"
                type="submit"
                :disabled="isDisabled"
              >
                {{ $t('Sign in') }}
              </FormKit>
            </template>
          </Form>
        </div>
      </div>
    </div>
    <div class="mb-6 flex items-center justify-center">
      <CommonLink link="/#login" class="!text-gray underline">
        {{ $t('Continue to desktop app') }}
      </CommonLink>
    </div>
    <div class="flex items-center justify-center align-middle text-gray-200">
      <CommonLink
        link="https://zammad.org"
        external
        open-in-new-tab
        class="ltr:mr-1 rtl:ml-1"
      >
        <CommonIcon name="logo" :fixed-size="{ width: 24, height: 24 }" />
      </CommonLink>
      <span class="ltr:mr-1 rtl:ml-1">{{ $t('Powered by') }}</span>
      <CommonLink
        link="https://zammad.org"
        external
        open-in-new-tab
        class="font-semibold !text-gray-200"
      >
        Zammad
      </CommonLink>
    </div>
  </div>
</template>
