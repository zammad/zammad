<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { shallowRef } from 'vue'
import { useRouter } from 'vue-router'

import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import useFingerprint from '#shared/composables/useFingerprint.ts'
import type { SignupFormData } from '#shared/entities/user/types.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import { useSignupForm } from '#desktop/composables/authentication/useSignupForm.ts'

import GuidedSetupActionFooter from '../../components/GuidedSetupActionFooter.vue'
import { useSystemSetup } from '../../composables/useSystemSetup.ts'
import { useUserAddFirstAdminMutation } from '../../graphql/mutations/userAddFirstAdmin.api.ts'
import { systemSetupBeforeRouteEnterGuard } from '../../router/guards/systemSetupBeforeRouteEnterGuard.ts'
import { useSystemSetupInfoStore } from '../../stores/systemSetupInfo.ts'

defineOptions({
  beforeRouteEnter: systemSetupBeforeRouteEnterGuard,
})

const { setTitle } = useSystemSetup()

setTitle(__('Create Administrator Account'))

const router = useRouter()

const form = shallowRef()
const { signupSchema } = useSignupForm()

const { systemSetupUnlock } = useSystemSetupInfoStore()

const signup = async (data: SignupFormData) => {
  const { fingerprint } = useFingerprint()

  const sendSignup = new MutationHandler(
    useUserAddFirstAdminMutation({
      context: {
        headers: {
          'X-Browser-Fingerprint': fingerprint.value,
        },
      },
    }),
  )
  return sendSignup
    .send({
      input: {
        firstname: data.firstname,
        lastname: data.lastname,
        email: data.email,
        password: data.password,
      },
    })
    .then(async (result) => {
      const { setAuthenticatedSessionId } = useAuthenticationStore()
      if (
        await setAuthenticatedSessionId(
          result?.userAddFirstAdmin?.session?.id || null,
        )
      ) {
        // TODO: after auth handling should be at the end of the setup triggered again (maybe we need to remember it?).
        systemSetupUnlock(() => {
          router.push('/guided-setup/manual/system-information')
        })
      }
    })
}

const unlockCallback = () => {
  router.replace('/guided-setup')
}
</script>

<template>
  <Form
    id="admin-signup"
    ref="form"
    form-class="mb-2.5"
    :schema="signupSchema"
    @submit="signup($event as FormSubmitData<SignupFormData>)"
  />
  <GuidedSetupActionFooter
    :form="form"
    :submit-button-text="__('Create account')"
    @go-back="systemSetupUnlock(unlockCallback)"
  />
</template>
