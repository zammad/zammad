<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <!-- TODO: Only a dummy implementation for the login... -->
  <div class="flex h-full min-h-screen flex-col items-center px-7 pt-7 pb-4">
    <div class="m-auto w-full max-w-md">
      <div class="flex grow flex-col justify-center">
        <div class="my-5 grow">
          <div class="flex justify-center p-2">
            <CommonLogo />
          </div>
          <div class="mb-6 flex justify-center p-2 text-2xl font-extrabold">
            {{ applicationConfig.value.product_name }}
          </div>
          <template v-if="applicationConfig.value.maintenance_login">
            <!-- eslint-disable vue/no-v-html -->
            <div
              class="my-1 flex items-center rounded bg-green py-2 px-4 text-white"
              v-html="applicationConfig.value.maintenance_login_message"
            ></div>
          </template>
          <Form
            v-bind:schema="formSchema"
            class="text-left"
            v-on:submit="login"
          >
            <template v-slot:after-fields>
              <div class="mt-4 flex grow items-center justify-center">
                <span class="ltr:mr-1 rtl:ml-1">{{ i18n.t('New user?') }}</span>
                <CommonLink
                  v-bind:link="'TODO'"
                  class="cursor-pointer select-none !text-yellow underline"
                  >{{ i18n.t('Register') }}</CommonLink
                >
              </div>
              <FormKit
                wrapper-class="mx-8 mt-8 flex grow justify-center items-center"
                input-class="py-2 px-4 w-full h-14 text-xl font-semibold text-black bg-yellow rounded select-none"
                type="submit"
              >
                {{ i18n.t('Sign in') }}
              </FormKit>
            </template>
          </Form>
        </div>
      </div>
    </div>
    <div class="mb-6 flex items-center justify-center">
      <CommonLink link="TODO" class="!text-gray underline">
        {{ i18n.t('Continue to desktop app') }}
      </CommonLink>
    </div>
    <div class="flex items-center justify-center align-middle text-gray-200">
      <CommonLink
        link="https://zammad.org"
        is-external
        open-in-new-tab
        class="ltr:mr-1 rtl:ml-1"
      >
        <CommonIcon name="logo" v-bind:fixed-size="{ width: 24, height: 24 }" />
      </CommonLink>
      <span class="ltr:mr-1 rtl:ml-1">{{ i18n.t('Powered by') }}</span>
      <CommonLink
        link="https://zammad.org"
        is-external
        open-in-new-tab
        class="font-semibold !text-gray-200"
      >
        Zammad
      </CommonLink>
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
import { FormKitGroupValue } from '@formkit/core'
import Form from '@common/components/form/Form.vue'

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

const formSchema = [
  {
    type: 'text',
    name: 'login',
    label: __('Username / Email'),
    placeholder: __('Username / Email'),
    wrapperClass: 'relative floating-input',
    inputClass:
      'block mt-1 w-full h-14 text-sm bg-gray-500 rounded border-none focus:outline-none placeholder:text-transparent',
    labelClass:
      'absolute top-0 left-0 py-5 px-3 h-full text-base transition-all duration-100 ease-in-out origin-left pointer-events-none',
    sectionsSchema: forFloatingLabel,
    validation: 'required',
  },
  {
    type: 'password',
    label: __('Password'),
    name: 'password',
    placeholder: __('Password'),
    wrapperClass: 'relative floating-input',
    inputClass:
      'block mt-1 w-full h-14 text-sm bg-gray-500 rounded border-none focus:outline-none placeholder:text-transparent',
    labelClass:
      'absolute top-0 left-0 py-5 px-3 h-full text-base transition-all duration-100 ease-in-out origin-left pointer-events-none',
    sectionsSchema: forFloatingLabel,
    validation: 'required',
  },
  {
    isLayout: true,
    element: 'div',
    attrs: {
      class: 'mt-2 flex grow items-center justify-between text-white',
    },
    children: [
      {
        type: 'checkbox',
        label: __('Remember me'),
        name: 'remember_me',
        wrapperClass: 'inline-flex items-center',
        inputClass:
          'appearance-none h-4 w-4 border-[1.5px] border-white rounded-sm bg-transparent',
        innerClass: 'mr-2',
      },
      {
        isLayout: true,
        component: 'CommonLink',
        props: {
          class: 'text-right !text-white',
          link: 'TODO',
        },
        children: i18n.t('Forgot password?'),
      },
    ],
  },
]

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

const applicationConfig = useApplicationConfigStore()
</script>

<style lang="postcss">
.floating-input > .formkit-inner > input:focus,
.floating-input > .formkit-inner > input:not(:placeholder-shown) {
  @apply pt-8;
}

.floating-input:focus-within > label,
.floating-input[data-has-value] > label {
  @apply -translate-y-3 translate-x-1 scale-75 opacity-75;
}
</style>
