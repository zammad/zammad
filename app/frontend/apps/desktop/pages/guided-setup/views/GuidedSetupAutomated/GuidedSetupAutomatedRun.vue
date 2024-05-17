<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'

import useFingerprint from '#shared/composables/useFingerprint.ts'
import type UserError from '#shared/errors/UserError.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPage.vue'

// TODO: check
// eslint-disable-next-line import/no-restricted-paths
import { ensureAfterAuth } from '../../../authentication/after-auth/composable/useAfterAuthPlugins.ts'
import GuidedSetupStatusMessage from '../../components/GuidedSetupStatusMessage.vue'
import { useSystemSetupRunAutoWizardMutation } from '../../graphql/mutations/systemSetupRunAutoWizard.api.ts'

interface Props {
  token?: string
}

const props = defineProps<Props>()

const { fingerprint } = useFingerprint()

const router = useRouter()

const finished = ref(false)
const errors = ref<UserError | undefined>()

const runAutoWizardMutation = new MutationHandler(
  useSystemSetupRunAutoWizardMutation({
    variables: { token: props.token },
    context: {
      headers: {
        'X-Browser-Fingerprint': fingerprint.value,
      },
    },
  }),
)

runAutoWizardMutation
  .send()
  .then(async (result) => {
    finished.value = true
    const { setAuthenticatedSessionId } = useAuthenticationStore()
    if (
      await setAuthenticatedSessionId(
        result?.systemSetupRunAutoWizard?.session?.id || null,
      )
    ) {
      const afterAuth = result?.systemSetupRunAutoWizard?.session?.afterAuth

      // Redirect only after some seconds, in order to give the user a chance to read the message.
      window.setTimeout(() => {
        if (afterAuth) {
          ensureAfterAuth(router, afterAuth)
          return
        }

        router.replace('/')
      }, 2000)
    }
  })
  .catch((error: UserError) => {
    errors.value = error
  })

const statusMessage = computed(() => {
  if (finished.value)
    return __(
      'The system was configured successfully. You are being redirected.',
    )

  return __('Relax, your system is being set up…')
})
</script>

<template>
  <LayoutPublicPage box-size="medium" :title="__('Automated Setup')">
    <GuidedSetupStatusMessage v-if="!errors" :message="statusMessage" />
    <CommonAlert v-else variant="danger">{{
      errors?.generalErrors[0]
    }}</CommonAlert>
  </LayoutPublicPage>
</template>
