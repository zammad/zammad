<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { getCSRFToken } from '#shared/server/apollo/utils/csrfToken.ts'
import type { ThirdPartyAuthProvider } from '#shared/types/authentication.ts'

export interface Props {
  providers: ThirdPartyAuthProvider[]
}

defineProps<Props>()

const csrfToken = getCSRFToken()
</script>

<template>
  <section class="mt-4 mb-16 w-full max-w-md" data-test-id="loginThirdParty">
    <p class="p-3 text-center">
      {{ $c.user_show_password_login ? $t('Or sign in using') : $t('Sign in using') }}
    </p>
    <div class="-m-2 flex flex-wrap p-1">
      <form
        v-for="provider of providers"
        :key="provider.name"
        class="flex min-w-1/2 grow"
        method="post"
        :action="provider.url"
      >
        <input type="hidden" name="authenticity_token" :value="csrfToken" />
        <button
          class="m-1 flex h-14 w-full cursor-pointer items-center justify-center rounded-xl bg-gray-600 px-4 py-2 text-white select-none"
        >
          <CommonIcon
            :name="provider.icon"
            size="base"
            decorative
            class="shrink-0 ltr:mr-2.5 rtl:ml-2.5"
          />
          <span class="truncate text-xl leading-7">
            {{ $t(provider.label) }}
          </span>
        </button>
      </form>
    </div>
  </section>
</template>
