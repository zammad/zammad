<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <!-- TODO: Only a dummy implementation for the login... -->
  <div class="flex flex-col h-full min-h-screen items-center justify-center">
    <div class="max-w-sm w-full">
      <div class="m-auto">
        <div class="flex-grow flex flex-col justify-center">
          <p>{{ i18n.t('Log in with %s', config.get('fqdn') as string) }}</p>

          <div class="my-5 p-5 max-w-full bg-white flex-grow rounded-md">
            <div class="flex flex-col">
              <div class="flex justify-center p-4">
                <CommonLogo />
              </div>

              <div class="text-left">
                <label class="block mt-4 cursor-pointer">
                  <span class="text-gray-600 uppercase text-xs tracking-wide">
                    {{ i18n.t('Username / Email') }}
                  </span>
                  <input
                    v-model="loginFormValues.login"
                    type="text"
                    class="text-gray-700 mt-1 block w-full text-sm rounded border border-gray-200"
                  />
                </label>

                <label class="block mt-4 cursor-pointer">
                  <span class="text-gray-600 uppercase text-xs tracking-wide">
                    {{ i18n.t('Password') }}
                  </span>
                  <input
                    v-model="loginFormValues.password"
                    type="password"
                    class="text-gray-700 mt-1 block w-full text-sm rounded border border-gray-200"
                  />
                </label>

                <label
                  class="mt-4 cursor-pointer inline-flex items-center select-none"
                >
                  <input type="checkbox" class="form-checkbox" checked />
                  <span class="ml-2">{{ i18n.t('Remember me') }}</span>
                </label>
              </div>

              <div class="flex justify-between flex-grow items-baseline mt-4">
                <button
                  class="bg-blue-500 hover:bg-blue-600 text-white py-2 px-4 rounded select-none"
                  v-on:click="login"
                >
                  {{ i18n.t('Sign in') }}
                </button>

                <a class="cursor-pointer select-none underline">
                  {{ i18n.t('Forgot password?') }}
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="flex justify-center items-center align-baseline p-6">
        <a href="https://zammad.org" target="_blank">
          <CommonIcon name="logo" size="large" />
        </a>

        <span class="mx-1">{{ i18n.t('Powered by') }}</span>

        <a class="ml-1 -mt-1" href="https://zammad.org" target="_blank">
          <CommonIcon
            name="logotype"
            v-bind:fixed-size="{ width: 80, height: 14 }"
          />
        </a>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import useNotifications from '@common/composables/useNotifications'
import useApplicationConfigStore from '@common/stores/application/config'
import useAuthenticationStore from '@common/stores/authenticated'
import { useRouter } from 'vue-router'
import { NotificationTypes } from '@common/types/notification'
import CommonLogo from '@common/components/common/CommonLogo.vue'

interface Props {
  invalidatedSession?: string
}

const props = defineProps<Props>()

// Output a hint, when the session is longer valid, maybe because because the session
// was deleted on the server.
if (props.invalidatedSession === '1') {
  const { notify } = useNotifications()

  notify({
    message: __('The session is no longer valid. Please log in again.'),
    type: NotificationTypes.WARN,
  })
}

const authentication = useAuthenticationStore()
const loginFormValues = {
  login: '',
  password: '',
}

const router = useRouter()

const login = (): void => {
  authentication
    .login(loginFormValues.login, loginFormValues.password)
    .then(() => {
      router.replace('/')
    })
}

const config = useApplicationConfigStore()
</script>
