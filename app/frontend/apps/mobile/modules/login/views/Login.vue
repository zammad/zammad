<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'
import {
  useNotifications,
  NotificationTypes,
} from '@shared/components/CommonNotifications'
import useAuthenticationStore from '@shared/stores/authentication'
import CommonLogo from '@shared/components/CommonLogo/CommonLogo.vue'
import useApplicationStore from '@shared/stores/application'
import { i18n } from '@shared/i18n'
import Form from '@shared/components/Form/Form.vue'
import { FormData } from '@shared/components/Form'
import { FormSchemaId } from '@shared/graphql/types'
import UserError from '@shared/errors/UserError'

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

interface LoginFormData {
  login?: string
  password?: string
  remember_me?: boolean
}

const login = (formData: FormData<LoginFormData>) => {
  authentication
    .login(formData.login as string, formData.password as string)
    .then(() => {
      router.replace('/')
    })
    .catch((errors: UserError) => {
      const { notify } = useNotifications()
      notify({
        message: errors.generalErrors[0],
        type: NotificationTypes.ERROR,
      })
    })
}

const application = useApplicationStore()
</script>

<template>
  <!-- TODO: Only a "first" dummy implementation for the login... -->
  <div class="flex h-full min-h-screen flex-col items-center px-7 pt-7 pb-4">
    <div class="m-auto w-full max-w-md">
      <div class="flex grow flex-col justify-center">
        <div class="my-5 grow">
          <div class="flex justify-center p-2">
            <CommonLogo />
          </div>
          <div class="mb-6 flex justify-center p-2 text-2xl font-extrabold">
            {{ application.config.product_name }}
          </div>
          <template v-if="application.config.maintenance_login">
            <!-- eslint-disable vue/no-v-html -->
            <div
              class="my-1 flex items-center rounded-xl bg-green py-2 px-4 text-white"
              v-html="application.config.maintenance_login_message"
            ></div>
          </template>
          <Form
            ref="form"
            class="text-left"
            :form-schema-id="FormSchemaId.FormSchemaFormMobileLogin"
            @submit="login"
          >
            <template #after-fields>
              <div class="mt-4 flex grow items-center justify-center">
                <span class="ltr:mr-1 rtl:ml-1">{{ i18n.t('New user?') }}</span>
                <CommonLink
                  :link="'TODO'"
                  class="cursor-pointer select-none !text-yellow underline"
                  >{{ i18n.t('Register') }}</CommonLink
                >
              </div>
              <FormKit
                wrapper-class="mx-8 mt-8 flex grow justify-center items-center"
                input-class="py-2 px-4 w-full h-14 text-xl font-semibold text-black bg-yellow rounded-xl select-none"
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
        <CommonIcon name="logo" :fixed-size="{ width: 24, height: 24 }" />
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
