<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRoute, useRouter } from 'vue-router'
import {
  useNotifications,
  NotificationTypes,
} from '#shared/components/CommonNotifications/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { computed, reactive, ref } from 'vue'
import { useThirdPartyAuthentication } from '#shared/composables/useThirdPartyAuthentication.ts'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForceDesktop } from '#shared/composables/useForceDesktop.ts'
import { useTwoFactorPlugins } from '#shared/entities/two-factor/composables/useTwoFactorPlugins.ts'
import type UserError from '#shared/errors/UserError.ts'
import type {
  EnumTwoFactorAuthenticationMethod,
  UserTwoFactorMethods,
} from '#shared/graphql/types.ts'
import LoginThirdParty from '../components/LoginThirdParty.vue'
import LoginCredentialsForm from '../components/LoginCredentialsForm.vue'
import LoginHeader from '../components/LoginHeader.vue'
import LoginTwoFactor from '../components/LoginTwoFactor.vue'
import LoginTwoFactorMethods from '../components/LoginTwoFactorMethods.vue'
import LoginRecoveryCode from '../components/LoginRecoveryCode.vue'
import { usePublicLinks } from '../composable/usePublicLinks.ts'
import type { LoginFlow, LoginFormData } from '../types/login.ts'
import LoginFooter from '../components/LoginFooter.vue'

const route = useRoute()
const router = useRouter()

const { notify } = useNotifications()

// Output a hint when the session is no longer valid.
// This could happen because the session was deleted on the server.
if (route.query.invalidatedSession === '1') {
  notify({
    message: __('The session is no longer valid. Please log in again.'),
    type: NotificationTypes.Warn,
  })

  router.replace({ name: 'Login' })
}

const application = useApplicationStore()

const { links } = usePublicLinks()

const { enabledProviders, hasEnabledProviders } = useThirdPartyAuthentication()

const showPasswordLogin = computed(
  () =>
    application.config.user_show_password_login || !hasEnabledProviders.value,
)

const { forceDesktop } = useForceDesktop()
const { twoFactorPlugins, twoFactorMethods } = useTwoFactorPlugins()

const finishLogin = () => {
  // TODO: maybe we need some additional logic for the ThirtParty-Login situtation.
  const { redirect: redirectUrl } = route.query
  if (typeof redirectUrl === 'string') {
    router.replace(redirectUrl)
  } else {
    router.replace('/')
  }
}

const loginFlow = reactive<LoginFlow>({
  state: 'credentials',
  allowedMethods: [],
  recoveryCodesAvailable: false,
})

const statePreviousMap = {
  credentials: null,
  '2fa': 'credentials',
  '2fa-select': '2fa',
  'recovery-code': '2fa-select',
} satisfies Record<string, LoginFlow['state'] | null>

const states = ref<LoginFlow['state'][]>([loginFlow.state])

const goBack = () => {
  const preivousState = statePreviousMap[loginFlow.state] || 'credentials'
  loginFlow.state = preivousState
  // if we go to the first state, reset credentials
  if (preivousState === 'credentials') {
    loginFlow.credentials = undefined
  }
}

const updateState = (state: LoginFlow['state']) => {
  states.value.push(state)
  loginFlow.state = state
}

const updateSecondFactor = (factor: EnumTwoFactorAuthenticationMethod) => {
  loginFlow.twoFactor = factor
  updateState('2fa')
}

const askTwoFactor = (
  twoFactor: UserTwoFactorMethods,
  formData: FormSubmitData<LoginFormData>,
) => {
  loginFlow.credentials = formData
  loginFlow.recoveryCodesAvailable = twoFactor.recoveryCodesAvailable
  loginFlow.allowedMethods = twoFactor.availableTwoFactorAuthenticationMethods
  updateSecondFactor(
    twoFactor.defaultTwoFactorAuthenticationMethod as EnumTwoFactorAuthenticationMethod,
  )
}

const twoFactorAllowedMethods = computed(() => {
  return twoFactorMethods.filter((method) =>
    loginFlow.allowedMethods.includes(method.name),
  )
})

const twoFactorPlugin = computed(() => {
  return loginFlow.twoFactor ? twoFactorPlugins[loginFlow.twoFactor] : undefined
})

const loginPageTitle = computed(() => {
  const productName = application.config.product_name
  if (loginFlow.state === 'credentials') return productName
  if (loginFlow.state === 'recovery-code') return __('Recovery Code')
  if (loginFlow.state === '2fa') {
    return twoFactorPlugin.value?.label ?? productName
  }
  return __('Try Another Method')
})

const showError = (error: UserError) => {
  notify({
    message: error.generalErrors[0],
    type: NotificationTypes.Error,
  })
}

const hasAlternativeLoginMethod = computed(() => {
  return (
    twoFactorAllowedMethods.value.length > 1 || loginFlow.recoveryCodesAvailable
  )
})
</script>

<template>
  <div class="flex h-full min-h-screen flex-col items-center px-6 pb-4 pt-6">
    <div v-if="statePreviousMap[loginFlow.state]" class="flex w-full">
      <button
        class="cursor-pointer"
        :aria-label="__('Go back')"
        @click="goBack"
      >
        <CommonIcon name="mobile-chevron-left" decorative />
      </button>
    </div>
    <main class="m-auto w-full max-w-md">
      <div class="flex grow flex-col justify-center">
        <div class="my-5 grow">
          <LoginHeader :title="loginPageTitle" />
          <LoginCredentialsForm
            v-if="loginFlow.state === 'credentials' && showPasswordLogin"
            @ask-two-factor="askTwoFactor"
            @error="showError"
            @finish="finishLogin"
          />
          <LoginTwoFactor
            v-else-if="
              loginFlow.state === '2fa' &&
              twoFactorPlugin &&
              loginFlow.credentials
            "
            :credentials="loginFlow.credentials"
            :two-factor="twoFactorPlugin"
            @error="showError"
            @finish="finishLogin"
          />
          <LoginRecoveryCode
            v-else-if="
              loginFlow.state === 'recovery-code' && loginFlow.credentials
            "
            :credentials="loginFlow.credentials"
            @error="showError"
            @finish="finishLogin"
          />
          <LoginTwoFactorMethods
            v-else-if="loginFlow.state === '2fa-select'"
            :methods="twoFactorAllowedMethods"
            :recovery-codes-available="loginFlow.recoveryCodesAvailable"
            @select="updateSecondFactor"
            @use-recovery-code="updateState('recovery-code')"
          />
        </div>
      </div>
      <section
        v-if="
          (loginFlow.state === '2fa' || loginFlow.state === 'recovery-code') &&
          hasAlternativeLoginMethod
        "
        class="text-center"
      >
        {{ $t('Having problems?') }}
        <button
          class="cursor-pointer pb-2 font-semibold leading-4 text-gray"
          @click.prevent="updateState('2fa-select')"
        >
          {{ $t('Try another method') }}
        </button>
      </section>
    </main>
    <LoginThirdParty
      v-if="hasEnabledProviders && loginFlow.state === 'credentials'"
      :providers="enabledProviders"
    />
    <section v-if="!showPasswordLogin" class="mb-6 w-full max-w-md text-center">
      <p>
        {{
          $t(
            'If you have problems with the third-party login you can request a one-time password login as an admin.',
          )
        }}
      </p>
      <CommonLink link="/#admin_password_auth" class="font-semibold text-gray">
        {{ $t('Request the password login here.') }}
      </CommonLink>
    </section>
    <div
      v-if="loginFlow.state !== 'credentials' && !hasAlternativeLoginMethod"
      class="pb-2 font-medium leading-4 text-gray"
    >
      {{ $t('Contact the administrator if you have any problems logging in.') }}
    </div>
    <CommonLink
      link="/#login"
      class="font-medium leading-4 text-gray"
      @click="forceDesktop"
    >
      {{ $t('Continue to desktop') }}
    </CommonLink>
    <nav
      v-if="links.length"
      class="mt-4 flex w-full max-w-md flex-wrap items-center justify-center gap-1"
    >
      <template v-for="link in links" :key="link.id">
        <CommonLink
          :link="link.link"
          :title="link.description"
          :open-in-new-tab="link.newTab"
          class="font-semibold leading-4 tracking-wide text-gray after:ml-1 after:font-medium after:text-gray-200 after:content-['|'] last:after:content-none"
        >
          {{ $t(link.title) }}
        </CommonLink>
      </template>
    </nav>
    <LoginFooter />
  </div>
</template>
