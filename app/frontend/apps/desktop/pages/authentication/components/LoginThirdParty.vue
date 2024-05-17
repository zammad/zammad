<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import useFingerprint from '#shared/composables/useFingerprint.ts'
import type { ThirdPartyAuthProvider } from '#shared/types/authentication.ts'

import CommonThirdPartyAuthenticationButton from '#desktop/components/CommonThirdPartyAuthenticationButton/CommonThirdPartyAuthenticationButton.vue'

export interface Props {
  providers: ThirdPartyAuthProvider[]
}

const props = defineProps<Props>()

const { fingerprint } = useFingerprint()
</script>

<template>
  <section class="mt-2.5 w-full" data-test-id="loginThirdParty">
    <div class="mb-2.5 flex justify-center">
      <CommonLabel>
        {{
          $c.user_show_password_login
            ? $t('Or sign in using')
            : $t('Sign in using')
        }}
      </CommonLabel>
    </div>
    <div class="flex flex-wrap gap-2">
      <CommonThirdPartyAuthenticationButton
        v-for="provider of props.providers"
        :key="provider.name"
        class="flex min-w-[calc(50%-theme(spacing.2))] grow"
        :url="`${provider.url}?fingerprint=${fingerprint}`"
        :button-prefix-icon="provider.icon"
        button-size="large"
        button-block
        button-variant="primary"
        :button-label="provider.name"
      >
        {{ $t(provider.label) }}
      </CommonThirdPartyAuthenticationButton>
    </div>
  </section>
</template>
