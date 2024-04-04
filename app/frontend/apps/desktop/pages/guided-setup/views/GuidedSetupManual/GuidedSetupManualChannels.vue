<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import GuidedSetupActionFooter from '../../components/GuidedSetupActionFooter.vue'
import { useSystemSetup } from '../../composables/useSystemSetup.ts'
import { emailBeforeRouteEnterGuard } from '../../router/guards/emailBeforeRouteEnterGuard.ts'

defineOptions({
  beforeRouteEnter: emailBeforeRouteEnterGuard,
})

const router = useRouter()

const { setTitle } = useSystemSetup()

setTitle(__('Connect Channels'))

const setupEmailChannel = () => {
  router.push('channels/email')
}
</script>

<template>
  <div class="mb-2.5 flex flex-col items-center justify-center gap-5">
    <CommonLabel class="text-center">
      {{
        $t(
          'Set up the communication channels you want to use with your Zammad.',
        )
      }}
    </CommonLabel>
    <CommonButton variant="primary" size="large" @click="setupEmailChannel()">
      {{ $t('Email Channel') }}
    </CommonButton>
  </div>
  <GuidedSetupActionFooter
    go-back-route="/guided-setup/manual/email-notification"
    skip-route="/guided-setup/manual/finish"
  />
</template>
