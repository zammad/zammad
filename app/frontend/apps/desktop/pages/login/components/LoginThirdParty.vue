<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import useFingerprint from '#shared/composables/useFingerprint.ts'
import { getCSRFToken } from '#shared/server/apollo/utils/csrfToken.ts'
import type { ThirdPartyAuthProvider } from '#shared/types/authentication.ts'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

export interface Props {
  providers: ThirdPartyAuthProvider[]
}

const props = defineProps<Props>()

const csrfToken = getCSRFToken()

const { fingerprint } = useFingerprint()
</script>

<template>
  <section class="w-full mt-2.5" data-test-id="loginThirdParty">
    <div class="flex justify-center mb-2.5">
      <CommonLabel>
        {{
          $c.user_show_password_login
            ? $t('Or sign in using')
            : $t('Sign in using')
        }}
      </CommonLabel>
    </div>
    <div class="flex flex-wrap gap-2">
      <form
        v-for="provider of props.providers"
        :key="provider.name"
        class="flex min-w-[calc(50%-theme(spacing.2))] grow"
        method="post"
        :action="`${provider.url}?fingerprint=${fingerprint}`"
      >
        <input type="hidden" name="authenticity_token" :value="csrfToken" />
        <CommonButton
          type="submit"
          variant="primary"
          size="large"
          block
          :prefix-icon="provider.icon"
        >
          {{ $t(provider.name) }}
        </CommonButton>
      </form>
    </div>
  </section>
</template>
