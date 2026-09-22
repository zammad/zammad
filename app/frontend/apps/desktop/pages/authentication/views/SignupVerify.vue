<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'

import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPage.vue'

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
      return __('Email could not be verified. Please contact your administrator.')
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

  const userSignupVerify = new MutationHandler(
    useUserSignupVerifyMutation({
      variables: { token: props.token },
    }),
    {
      errorShowNotification: false,
    },
  )

  userSignupVerify
    .send()
    .then((result) => {
      if (!result?.userSignupVerify?.success) {
        setState('error')
        return
      }

      setState('success')

      // Redirect only after some seconds, in order to give the user a chance to read the message.
      window.setTimeout(() => {
        router.replace('/login')
      }, 2000)
    })
    .catch(() => {
      setState('error')
    })
})
</script>

<template>
  <LayoutPublicPage box-size="small" :title="__('Email verification')">
    <div class="mt-1 text-center">
      <CommonLabel>
        {{ $t(message) }}
      </CommonLabel>
      <CommonLabel v-if="state === 'success'" class="mt-1 block">
        {{ $t('Please sign in to continue.') }}
      </CommonLabel>
      <CommonLoader v-if="state === 'loading'" loading class="mt-9 mb-3" />
      <CommonIcon
        v-else-if="state === 'success'"
        class="mx-auto mt-9 mb-3 fill-green-500"
        name="check-circle-outline"
      />
      <CommonIcon
        v-else-if="state === 'error'"
        class="mx-auto mt-9 mb-3 fill-red-500"
        name="x-circle"
      />
    </div>
  </LayoutPublicPage>
</template>
