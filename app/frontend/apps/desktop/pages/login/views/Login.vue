<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRoute, useRouter } from 'vue-router'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import {
  useNotifications,
  NotificationTypes,
} from '#shared/components/CommonNotifications/index.ts'
import UserError from '#shared/errors/UserError.ts'
import Form from '#shared/components/Form/Form.vue'
import CommonLogo from '#shared/components/CommonLogo/CommonLogo.vue'
import { useApplicationStore } from '#shared/stores/application.ts'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'

const application = useApplicationStore()

const router = useRouter()
const route = useRoute()

const { notify } = useNotifications()

const authentication = useAuthenticationStore()

interface LoginCredentials {
  login: string
  password: string
  rememberMe: boolean
}

const login = async (credentials: LoginCredentials) => {
  try {
    await authentication.login(credentials)
    const { redirect: redirectUrl } = route.query
    router.replace(typeof redirectUrl === 'string' ? redirectUrl : '/')
  } catch (error) {
    const message =
      error instanceof UserError ? error.generalErrors[0] : String(error)
    notify({
      message,
      type: NotificationTypes.Error,
    })
  }
}

const loginSchema = [
  {
    name: 'login',
    type: 'text',
    label: __('Username / Email'),
    required: true,
  },
  {
    name: 'password',
    label: __('Password'),
    type: 'password',
    required: true,
  },
  {
    isLayout: true,
    element: 'div',
    attrs: {
      class: 'mt-2.5 flex grow items-center justify-between',
    },
    children: [
      {
        type: 'checkbox',
        name: 'rememberMe',
        label: __('Remember me'),
        value: false,
      },
      // TODO support if/then in form-schema
      ...(application.config.user_lost_password
        ? [
            {
              isLayout: true,
              component: 'CommonLink',
              props: {
                class: 'link-primary text-right',
                link: '/#password_reset',
                onClick(e: Event) {
                  e.preventDefault()
                  // eslint-disable-next-line no-alert
                  window.alert('LOL')
                },
              },
              children: __('Forgot password?'),
            },
          ]
        : []),
    ],
  },
]

const { form, isDisabled } = useForm()
</script>

<template>
  <div class="min-h-screen flex flex-col items-center">
    <div class="group-block max-w-md w-full m-auto">
      <div class="flex justify-center p-2">
        <CommonLogo />
      </div>
      <h1 class="mb-6 flex justify-center p-2 text-2xl font-extrabold">
        {{ $c.product_name }}
      </h1>
      <template v-if="$c.maintenance_mode">
        <div
          class="my-1 flex items-center rounded-xl bg-red px-4 py-2 text-white"
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
          class="my-1 flex items-center rounded-xl bg-green px-4 py-2 text-white"
          v-html="$c.maintenance_login_message"
        ></div>
      </template>

      <!-- TODO: there was no design with login, so I am using "reply" block -->
      <Form
        id="signing"
        ref="form"
        form-class="mb-3 space-y-2"
        :schema="loginSchema"
        @submit="login($event as FormSubmitData<LoginCredentials>)"
      >
        <template #after-fields>
          <button
            class="btn btn-accent btn-block text-base"
            :disabled="isDisabled"
          >
            {{ $t('Sign in') }}
          </button>
        </template>
      </Form>
    </div>

    <div
      class="mt-4 flex w-full max-w-md justify-center border-t border-base-300 py-4 text-base leading-4"
    >
      <a
        v-if="application.hasCustomProductBranding"
        href="https://zammad.org"
        target="_blank"
        class="ltr:mr-1 rtl:ml-1"
      >
        <img
          :src="'/assets/images/icons/logo.svg'"
          :alt="$t('Logo')"
          class="h-6 w-6"
        />
      </a>
      <span class="ltr:mr-1 rtl:ml-1">{{ $t('Powered by') }}</span>
      <a href="https://zammad.org" target="_blank" class="font-semibold">
        {{ $t('Zammad') }}
      </a>
    </div>
  </div>
</template>
