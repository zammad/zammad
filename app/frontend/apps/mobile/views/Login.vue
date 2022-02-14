<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <!-- TODO: Only a dummy implementation for the login... -->
  <div class="flex flex-col justify-center items-center h-full min-h-screen">
    <div class="w-full max-w-md">
      <div class="flex flex-col grow justify-center">
        <div class="grow p-8 my-5">
          <div class="flex justify-center p-2">
            <CommonLogo />
          </div>
          <div class="flex justify-center p-2 mb-6 text-2xl font-extrabold">
            {{ 'Zammad' }}
          </div>
          <template v-if="authenticationConfig.value.maintenance_login">
            <!-- eslint-disable vue/no-v-html -->
            <div
              class="flex items-center py-2 px-4 my-1 text-white bg-green rounded"
              v-html="authenticationConfig.value.maintenance_login_message"
            ></div>
          </template>
          <FormKit
            type="form"
            form-class="text-left"
            v-bind:actions="false"
            v-on:submit="login"
          >
            <FormKitSchema v-bind:schema="formSchema" />
            <div class="flex grow justify-between items-baseline mt-1">
              <a class="text-yellow underline cursor-pointer select-none">
                {{ i18n.t('Register') }}
              </a>

              <a class="text-yellow cursor-pointer select-none">
                {{ i18n.t('Forgot password?') }}
              </a>
            </div>

            <FormKit
              v-bind:ignore="true"
              wrapper-class="flex grow justify-center items-center mx-8 mt-8"
              input-class="py-2 px-4 w-full h-14 text-xl font-semibold text-black bg-yellow rounded select-none"
              type="submit"
            >
              {{ i18n.t('Sign in') }}
            </FormKit>
          </FormKit>
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
import useApplicationConfigStore from '@common/stores/application/config'
import { i18n } from '@common/utils/i18n'
import { FormKit, FormKitSchema } from '@formkit/vue'
import { FormKitGroupValue } from '@formkit/core'
import { reactive } from 'vue'

interface Props {
  invalidatedSession?: string
}

const props = defineProps<Props>()

// Output a hint when the session is longer valid.
// This could happen because because the session was deleted on the server.
if (props.invalidatedSession === '1') {
  const { notify } = useNotifications()

  notify({
    message: __('The session is no longer valid. Please log in again.'),
    type: NotificationTypes.WARN,
  })
}

const authentication = useAuthenticationStore()

const router = useRouter()

const forFloatingLabel = {
  wrapper: {
    attrs: {
      'data-has-value': {
        if: '$_value != "" && $fns.string($_value) !== "undefined"',
        then: 'true',
        else: undefined,
      },
    },
  },
}

const formSchema = reactive([
  {
    $formkit: 'text',
    name: 'login',
    label: __('Username / Email'),
    labelPlaceholder: ['replaced'],
    placeholder: __('Username / Email'),
    wrapperClass: 'relative floating-input',
    inputClass:
      'block mt-1 w-full h-14 text-sm bg-gray-300 rounded border-none focus:outline-none placeholder:text-transparent',
    labelClass:
      'absolute top-0 left-0 py-5 px-3 h-full text-base transition-all duration-100 ease-in-out origin-left pointer-events-none',
    __raw__sectionsSchema: forFloatingLabel,
    validation: 'required',
  },
  {
    $formkit: 'password',
    label: __('Password'),
    labelPlaceholder: ['replaced'],
    name: 'password',
    placeholder: __('Password'),
    wrapperClass: 'relative floating-input',
    inputClass:
      'block mt-1 w-full h-14 text-sm bg-gray-300 rounded border-none focus:outline-none placeholder:text-transparent',
    labelClass:
      'absolute top-0 left-0 py-5 px-3 h-full text-base transition-all duration-100 ease-in-out origin-left pointer-events-none',
    __raw__sectionsSchema: forFloatingLabel,
    validation: 'required',
  },
  // {
  //   $formkit: 'select',
  //   label: __('Select'),
  //   labelPlaceholder: ['replaced'],
  //   name: 'select',
  //   placeholder: __('Select'),
  //   wrapperClass: 'relative floating-input',
  //   inputClass:
  //     'block mt-1 w-full h-14 text-sm bg-gray-300 rounded border-none focus:outline-none placeholder:text-transparent',
  //   labelClass:
  //     'absolute top-0 left-0 py-5 px-3 h-full text-base transition-all duration-100 ease-in-out origin-left pointer-events-none',
  //   options: ['1', '2', '3', '4'],
  //   __raw__sectionsSchema: forFloatingLabel,
  //   validation: 'required',
  // },
])

interface FormData {
  login: string
  password: string
}

const login = (formData: FormKitGroupValue): void => {
  const data = formData as unknown as FormData
  authentication
    .login(data.login, data.password)
    .then(() => {
      router.replace('/')
    })
    .catch((errors) => {
      const { notify } = useNotifications()
      notify({
        message: errors[0],
        type: NotificationTypes.ERROR,
      })
    })
}

const authenticationConfig = useApplicationConfigStore()
</script>

<style lang="postcss">
.floating-input > .formkit-inner > input:focus,
.floating-input > .formkit-inner > input:not(:placeholder-shown) {
  @apply pt-8;
}

.floating-input:focus-within > label,
.floating-input[data-has-value] > label {
  @apply opacity-75 scale-75 -translate-y-3 translate-x-1;
}
</style>
