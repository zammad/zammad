<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <!-- TODO: Only a dummy implementation for the login... -->
  <div class="flex flex-col h-full min-h-screen items-center justify-center">
    <div class="max-w-md w-full">
      <div class="flex-grow flex flex-col justify-center">
        <div class="my-5 p-8 flex-grow">
          <div class="flex justify-center p-2">
            <CommonLogo />
          </div>
          <div class="flex justify-center p-2 mb-6 font-extrabold text-2xl">
            {{ 'Zammad' }}
          </div>

          <form class="text-left">
            <fieldset class="floating-input relative">
              <input
                id="username"
                v-model="loginFormValues.login"
                type="text"
                v-bind:placeholder="i18n.t('Username / Email')"
                class="block h-14 bg-gray-300 mt-1 w-full text-sm rounded border-none focus:outline-none"
              />
              <label
                for="username"
                class="absolute top-0 left-0 px-3 py-5 h-full pointer-events-none transform origin-left transition-all duration-100 ease-in-out text-base"
              >
                {{ i18n.t('Username / Email') }}
              </label>
            </fieldset>

            <fieldset class="floating-input relative">
              <input
                id="password"
                v-model="loginFormValues.password"
                type="password"
                v-bind:placeholder="i18n.t('Password')"
                class="block h-14 bg-gray-300 mt-1 w-full text-sm rounded border-none focus:outline-none"
              />
              <label
                for="password"
                class="absolute top-0 left-0 px-3 py-5 h-full pointer-events-none transform origin-left transition-all duration-100 ease-in-out text-base"
              >
                {{ i18n.t('Password') }}
              </label>
            </fieldset>

            <!-- <label
                  class="mt-4 cursor-pointer inline-flex items-center select-none"
                >
                  <input type="checkbox" />
                  <span class="ml-2">{{ i18n.t('Remember me') }}</span>
                </label> -->
          </form>

          <div class="flex justify-between flex-grow items-baseline mt-1">
            <a class="text-yellow cursor-pointer select-none underline">
              {{ i18n.t('Register') }}
            </a>

            <a class="text-yellow cursor-pointer select-none">
              {{ i18n.t('Forgot password?') }}
            </a>
          </div>

          <div class="flex flex-grow items-cemter justify-center mt-8 mx-8">
            <button
              class="h-14 bg-yellow text-black text-xl font-semibold w-full py-2 px-4 rounded select-none"
              v-on:click="login"
            >
              {{ i18n.t('Sign in') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import useNotifications from '@common/composables/useNotifications'
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
</script>

<style lang="postcss">
.floating-input > input::placeholder {
  color: transparent;
}

.floating-input > input:focus,
.floating-input > input:not(:placeholder-shown) {
  @apply pt-8;
}

.floating-input > input:focus ~ label,
.floating-input > input:not(:placeholder-shown) ~ label {
  @apply opacity-75 scale-75 -translate-y-3 translate-x-1;
}
</style>
