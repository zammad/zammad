<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, reactive } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import UserError from '#shared/errors/UserError.ts'
import Form from '#shared/components/Form/Form.vue'
import { useApplicationStore } from '#shared/stores/application.ts'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useThirdPartyAuthentication } from '#shared/composables/useThirdPartyAuthentication.ts'
import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage.vue'
import LoginThirdParty from '#desktop/pages/login/components/LoginThirdParty.vue'
import CommonPublicLinks from '#desktop/components/CommonPublicLinks/CommonPublicLinks.vue'
import { EnumPublicLinksScreen } from '#shared/graphql/types.ts'

const application = useApplicationStore()

const router = useRouter()
const route = useRoute()

const authentication = useAuthenticationStore()

const { enabledProviders, hasEnabledProviders } = useThirdPartyAuthentication()

const showPasswordLogin = computed(
  () =>
    application.config.user_show_password_login || !hasEnabledProviders.value,
)

interface LoginCredentials {
  login: string
  password: string
  rememberMe: boolean
}

const passwordLoginErrorMessage = ref('')

const login = async (credentials: LoginCredentials) => {
  try {
    await authentication.login(credentials)
    const { redirect: redirectUrl } = route.query
    router.replace(typeof redirectUrl === 'string' ? redirectUrl : '/')
  } catch (error) {
    passwordLoginErrorMessage.value =
      error instanceof UserError ? error.generalErrors[0] : String(error)
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
      class: 'flex grow items-center justify-between',
    },
    children: [
      {
        type: 'checkbox',
        name: 'rememberMe',
        label: __('Remember me'),
        value: false,
      },
      {
        if: '$userLostPassword === true',
        isLayout: true,
        component: 'CommonLink',
        props: {
          class: 'text-right text-sm',
          link: '/#password_reset',
          onClick(e: Event) {
            e.preventDefault()
            // eslint-disable-next-line no-alert
            window.alert('TEST')
          },
        },
        children: __('Forgot password?'),
      },
    ],
  },
]

const userLostPassword = computed(() => application.config.user_lost_password)

const schemaData = reactive({
  userLostPassword,
})

const { form, isDisabled } = useForm()
</script>

<template>
  <LayoutPublicPage box-size="small" :title="$c.product_name" show-logo>
    <div
      v-if="$c.maintenance_mode"
      class="my-1 flex items-center rounded-xl bg-red px-4 py-2 text-white"
    >
      {{
        $t(
          'Zammad is currently in maintenance mode. Only administrators can log in. Please wait until the maintenance window is over.',
        )
      }}
    </div>
    <!-- eslint-disable vue/no-v-html -->
    <div
      v-if="$c.maintenance_login && $c.maintenance_login_message"
      class="my-1 flex items-center rounded-xl bg-green px-4 py-2 text-white"
      v-html="$c.maintenance_login_message"
    ></div>

    <template v-if="showPasswordLogin">
      <CommonAlert v-if="passwordLoginErrorMessage" variant="danger">{{
        $t(passwordLoginErrorMessage)
      }}</CommonAlert>
      <Form
        id="signin"
        ref="form"
        form-class="mb-2.5 space-y-2.5"
        :schema="loginSchema"
        :schema-data="schemaData"
        @submit="login($event as FormSubmitData<LoginCredentials>)"
      >
        <template #after-fields> </template>
      </Form>
      <div class="flex justify-center py-3">
        <CommonLabel>
          {{ $t('New user?') }}
          <CommonLink link="/#signup" class="select-none">{{
            $t('Register')
          }}</CommonLink>
        </CommonLabel>
      </div>
      <CommonButton
        form="signin"
        type="submit"
        variant="submit"
        size="large"
        block
        :disabled="isDisabled"
      >
        {{ $t('Sign in') }}
      </CommonButton>
    </template>

    <LoginThirdParty v-if="hasEnabledProviders" :providers="enabledProviders" />

    <!-- TODO output of "If you have problems with the third-party login you can request a one-time password login as an admin." -->

    <template #bottomContent>
      <!-- TODO: Remember the choice when we have a switch between the two desktop apps -->
      <CommonLink class="text-sm" link="/mobile" external>
        {{ $t('Continue to mobile') }}
      </CommonLink>
      <CommonPublicLinks :screen="EnumPublicLinksScreen.Login" />
    </template>
  </LayoutPublicPage>
</template>
