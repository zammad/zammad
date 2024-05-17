<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import {
  useNotifications,
  NotificationTypes,
} from '#shared/components/CommonNotifications/index.ts'
import useLoginTwoFactor from '#shared/composables/authentication/useLoginTwoFactor.ts'
import { useThirdPartyAuthentication } from '#shared/composables/authentication/useThirdPartyAuthentication.ts'
import { useForceDesktop } from '#shared/composables/useForceDesktop.ts'
import { usePublicLinks } from '#shared/composables/usePublicLinks.ts'
import type UserError from '#shared/errors/UserError.ts'
import { EnumPublicLinksScreen } from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import LoginCredentialsForm from '../components/LoginCredentialsForm.vue'
import LoginFooter from '../components/LoginFooter.vue'
import LoginHeader from '../components/LoginHeader.vue'
import LoginRecoveryCode from '../components/LoginRecoveryCode.vue'
import LoginThirdParty from '../components/LoginThirdParty.vue'
import LoginTwoFactor from '../components/LoginTwoFactor.vue'
import LoginTwoFactorMethods from '../components/LoginTwoFactorMethods.vue'

const route = useRoute()
const router = useRouter()

const { notify, clearAllNotifications } = useNotifications()

// Output a hint when the session is no longer valid.
// This could happen because the session was deleted on the server.
if (route.query.invalidatedSession === '1') {
  notify({
    id: 'invalid-session',
    message: __('The session is no longer valid. Please log in again.'),
    type: NotificationTypes.Warn,
  })

  router.replace({ name: 'Login' })
}

const {
  loginFlow,
  askTwoFactor,
  twoFactorPlugin,
  twoFactorAllowedMethods,
  updateState,
  updateSecondFactor,
  hasAlternativeLoginMethod,
  goBack,
  statePreviousMap,
  loginPageTitle,
} = useLoginTwoFactor(clearAllNotifications)

const application = useApplicationStore()

const { links } = usePublicLinks(EnumPublicLinksScreen.Login)

const { enabledProviders, hasEnabledProviders } = useThirdPartyAuthentication()

const showPasswordLogin = computed(
  () =>
    application.config.user_show_password_login || !hasEnabledProviders.value,
)

const { forceDesktop } = useForceDesktop()

const finishLogin = () => {
  const { redirect: redirectUrl } = route.query
  if (typeof redirectUrl === 'string') {
    router.replace(redirectUrl)
  } else {
    router.replace('/')
  }
}

const showError = (error: UserError) => {
  notify({
    id: 'login-error',
    message: error.generalErrors[0],
    type: NotificationTypes.Error,
  })
}
</script>

<template>
  <div class="flex h-full min-h-screen flex-col items-center px-6 pb-4 pt-6">
    <div v-if="statePreviousMap[loginFlow.state]" class="flex w-full">
      <button
        class="cursor-pointer"
        :aria-label="__('Go back')"
        @click="goBack"
      >
        <CommonIcon name="chevron-left" decorative />
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
          class="text-gray cursor-pointer pb-2 font-semibold leading-4"
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
      <CommonLink
        link="/#admin_password_auth"
        class="text-gray font-semibold"
        @click="forceDesktop"
      >
        {{ $t('Request the password login here.') }}
      </CommonLink>
    </section>
    <div
      v-if="loginFlow.state !== 'credentials' && !hasAlternativeLoginMethod"
      class="text-gray pb-2 font-medium leading-4"
    >
      {{ $t('Contact the administrator if you have any problems logging in.') }}
    </div>
    <CommonLink
      link="/#login"
      class="text-gray font-medium leading-4"
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
          class="text-gray font-semibold leading-4 tracking-wide after:ml-1 after:font-medium after:text-gray-200 after:content-['|'] last:after:content-none"
        >
          {{ $t(link.title) }}
        </CommonLink>
      </template>
    </nav>
    <LoginFooter />
  </div>
</template>
