<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, reactive } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import CommonLink from '#shared/components/CommonLink/CommonLink.vue'
import Form from '#shared/components/Form/Form.vue'
import type {
  FormSubmitData,
  FormSchemaField,
  FormValues,
} from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import useLoginTwoFactor from '#shared/composables/authentication/useLoginTwoFactor.ts'
import { useThirdPartyAuthentication } from '#shared/composables/authentication/useThirdPartyAuthentication.ts'
import type { LoginCredentials } from '#shared/entities/two-factor/types.ts'
import UserError from '#shared/errors/UserError.ts'
import { EnumPublicLinksScreen } from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonPublicLinks from '#desktop/components/CommonPublicLinks/CommonPublicLinks.vue'
import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPage.vue'
import { useNewBetaUi } from '#desktop/composables/useNewBetaUi.ts'
import LoginThirdParty from '#desktop/pages/authentication/components/LoginThirdParty.vue'

import { ensureAfterAuth } from '../after-auth/composable/useAfterAuthPlugins.ts'
import LoginRecoveryCode from '../components/LoginRecoveryCode.vue'
import LoginTwoFactor from '../components/LoginTwoFactor.vue'
import LoginTwoFactorMethods from '../components/LoginTwoFactorMethods.vue'
import { useAdminPasswordAuthVerify } from '../composables/useAdminPasswordAuthVerify.ts'

const application = useApplicationStore()

const router = useRouter()
const route = useRoute()

const authentication = useAuthenticationStore()

const { enabledProviders, hasEnabledProviders } = useThirdPartyAuthentication()

const passwordLoginErrorMessage = ref('')

const showError = (error: UserError) => {
  passwordLoginErrorMessage.value = error.generalErrors[0]
}

const clearError = () => {
  passwordLoginErrorMessage.value = ''
}

const {
  loginFlow,
  askTwoFactor,
  twoFactorPlugin,
  twoFactorAllowedMethods,
  updateState,
  updateSecondFactor,
  hasAlternativeLoginMethod,
  loginPageTitle,
  cancelAndGoBack,
} = useLoginTwoFactor(clearError)

const finishLogin = () => {
  const { redirect: redirectUrl } = route.query
  if (typeof redirectUrl === 'string') {
    router.replace(redirectUrl)
  } else {
    router.replace('/')
  }
}

const login = async (credentials: LoginCredentials) => {
  try {
    const { twoFactor, afterAuth } = await authentication.login(credentials)

    if (afterAuth) {
      ensureAfterAuth(router, afterAuth)
      return
    }

    if (twoFactor?.defaultTwoFactorAuthenticationMethod) {
      askTwoFactor(twoFactor, credentials)
      return
    }

    finishLogin()
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
          link: '/reset-password',
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

const formInitialValues: FormValues = {}
const formChangeFields = reactive<Record<string, Partial<FormSchemaField>>>({})

const { verifyTokenResult, verifyTokenMessage, verifyTokenAlertVariant } =
  useAdminPasswordAuthVerify({
    formChangeFields,
    formInitialValues,
  })

const showPasswordLogin = computed(
  () =>
    application.config.user_show_password_login ||
    !hasEnabledProviders.value ||
    verifyTokenResult?.value,
)

const { switchValue, toggleBetaUiSwitch } = useNewBetaUi()
</script>

<template>
  <LayoutPublicPage box-size="small" :title="loginPageTitle" show-logo>
    <div
      v-if="$c.maintenance_mode"
      class="bg-red my-1 flex items-center rounded-xl px-4 py-2 text-white"
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
      class="bg-green my-1 flex items-center rounded-xl px-4 py-2 text-white"
      v-html="$c.maintenance_login_message"
    ></div>

    <CommonAlert v-if="verifyTokenMessage" :variant="verifyTokenAlertVariant">{{
      $t(verifyTokenMessage)
    }}</CommonAlert>

    <template v-if="showPasswordLogin">
      <CommonAlert v-if="passwordLoginErrorMessage" variant="danger">{{
        $t(passwordLoginErrorMessage)
      }}</CommonAlert>

      <Form
        v-if="loginFlow.state === 'credentials' && showPasswordLogin"
        id="login"
        ref="form"
        form-class="mb-2.5 space-y-2.5"
        :schema="loginSchema"
        :schema-data="schemaData"
        :initial-values="formInitialValues"
        :change-fields="formChangeFields"
        @submit="login($event as FormSubmitData<LoginCredentials>)"
      >
        <template #after-fields>
          <div v-if="$c.user_create_account" class="flex justify-center py-3">
            <CommonLabel>
              {{ $t('New user?') }}
              <CommonLink link="/signup" class="select-none" size="medium">{{
                $t('Register')
              }}</CommonLink>
            </CommonLabel>
          </div>
          <CommonButton
            type="submit"
            variant="submit"
            size="large"
            block
            :disabled="isDisabled"
          >
            {{ $t('Sign in') }}
          </CommonButton>
        </template>
      </Form>

      <LoginTwoFactor
        v-else-if="
          loginFlow.state === '2fa' && twoFactorPlugin && loginFlow.credentials
        "
        :credentials="loginFlow.credentials"
        :two-factor="twoFactorPlugin"
        @error="showError"
        @clear-error="clearError"
        @finish="finishLogin"
      />
      <LoginRecoveryCode
        v-else-if="loginFlow.state === 'recovery-code' && loginFlow.credentials"
        :credentials="loginFlow.credentials"
        @error="showError"
        @clear-error="clearError"
        @finish="finishLogin"
      />
      <LoginTwoFactorMethods
        v-else-if="loginFlow.state === '2fa-select'"
        :methods="twoFactorAllowedMethods"
        :default-method="loginFlow.defaultMethod"
        :recovery-codes-available="loginFlow.recoveryCodesAvailable"
        @select="updateSecondFactor"
        @use-recovery-code="updateState('recovery-code')"
        @cancel="cancelAndGoBack()"
      />

      <section
        v-if="
          (loginFlow.state === '2fa' || loginFlow.state === 'recovery-code') &&
          hasAlternativeLoginMethod
        "
        class="mt-3 text-center"
      >
        <CommonLabel>
          {{ $t('Having problems?') }}
          <CommonLink
            link="#"
            class="select-none"
            @click="updateState('2fa-select')"
          >
            {{ $t('Try another method') }}
          </CommonLink>
        </CommonLabel>
      </section>
    </template>

    <LoginThirdParty
      v-if="hasEnabledProviders && loginFlow.state === 'credentials'"
      :providers="enabledProviders"
    />

    <template #bottomContent>
      <div
        v-if="!showPasswordLogin"
        class="inline-flex flex-wrap items-center justify-center p-2 text-sm"
      >
        <CommonLabel class="text-center text-stone-200 dark:text-neutral-500">
          {{
            $t(
              'If you have problems with the third-party login you can request a one-time password login as an admin.',
            )
          }}
        </CommonLabel>
        <CommonLink link="/admin-password-auth">{{
          $t('Request the password login here.')
        }}</CommonLink>
      </div>

      <CommonLabel
        v-if="loginFlow.state === '2fa-select'"
        class="mt-3 mb-3 text-stone-200 dark:text-neutral-500"
      >
        {{
          $t('Contact the administrator if you have any problems logging in.')
        }}
      </CommonLabel>

      <div v-if="loginFlow.state === 'credentials'" class="mt-3">
        <CommonLink
          link="/mobile"
          class="after:mx-2 after:inline-block after:font-medium after:text-neutral-500 after:content-['|'] last:after:content-none"
          size="medium"
          external
        >
          {{ $t('Continue to mobile') }}
        </CommonLink>
        <CommonLink
          v-if="switchValue"
          size="medium"
          link="/"
          external
          @click="toggleBetaUiSwitch()"
        >
          {{ $t('Switch to old interface') }}
        </CommonLink>
      </div>
      <CommonPublicLinks :screen="EnumPublicLinksScreen.Login" />
    </template>
  </LayoutPublicPage>
</template>
