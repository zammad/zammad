<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'

import useFingerprint from '#shared/composables/useFingerprint.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPage.vue'

import { ensureAfterAuth } from '../after-auth/composable/useAfterAuthPlugins.ts'
import { useUserSignupVerifyMutation } from '../graphql/mutations/userSignupVerify.api.ts'

import type { VerifyState } from '../types/signup.ts'

defineOptions({
  beforeRouteEnter(to) {
    const application = useApplicationStore()
    if (!application.config.user_create_account) {
      return to.redirectedFrom ? false : '/'
    }
    return true
  },
})

interface Props {
  token?: string
}

const props = defineProps<Props>()

const router = useRouter()

const state = ref<VerifyState>('loading')

const setState = (newState: VerifyState) => {
  state.value = newState
}

const message = computed(() => {
  switch (state.value) {
    case 'success':
      return __('Woo hoo! Your email address has been verified!')
    case 'error':
      return __(
        'Email could not be verified. Please contact your administrator.',
      )
    case 'loading':
    default:
      return __('Verifying your email…')
  }
})

onMounted(() => {
  if (!props.token) {
    state.value = 'error'
    return
  }

  const { fingerprint } = useFingerprint()

  const userSignupVerify = new MutationHandler(
    useUserSignupVerifyMutation({
      variables: { token: props.token },
      context: {
        headers: {
          'X-Browser-Fingerprint': fingerprint.value,
        },
      },
    }),
    {
      errorShowNotification: false,
    },
  )

  userSignupVerify
    .send()
    .then(async (result) => {
      const { setAuthenticatedSessionId } = useAuthenticationStore()

      if (
        await setAuthenticatedSessionId(
          result?.userSignupVerify?.session?.id || null,
        )
      ) {
        setState('success')

        const afterAuth = result?.userSignupVerify?.session?.afterAuth

        // Redirect only after some seconds, in order to give the user a chance to read the message.
        window.setTimeout(() => {
          if (afterAuth) {
            ensureAfterAuth(router, afterAuth)
            return
          }

          router.replace('/')
        }, 2000)

        return
      }

      setState('error')
    })
    .catch(() => {
      setState('error')
    })
})
</script>

<template>
  <LayoutPublicPage box-size="small" :title="__('Email Verification')">
    <div class="mt-1 text-center">
      <CommonLabel>
        {{ $t(message) }}
      </CommonLabel>
      <CommonLoader v-if="state === 'loading'" class="mb-3 mt-9" loading />
      <CommonIcon
        v-else-if="state === 'success'"
        class="mx-auto mb-3 mt-9 fill-green-500"
        name="check-circle-outline"
      />
      <CommonIcon
        v-else-if="state === 'error'"
        class="mx-auto mb-3 mt-9 fill-red-500"
        name="x-circle"
      />
    </div>
  </LayoutPublicPage>
</template>
