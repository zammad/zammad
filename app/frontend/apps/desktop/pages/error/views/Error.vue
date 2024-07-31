<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import { errorOptions } from '#shared/router/error.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import { ErrorStatusCodes } from '#shared/types/error.ts'

import LayoutMain from '#desktop/components/layout/LayoutMain.vue'
import LayoutPage from '#desktop/components/layout/LayoutPage.vue'

const { authenticated } = storeToRefs(useAuthenticationStore())

const errorImage = computed(() => {
  switch (errorOptions.value.statusCode) {
    case ErrorStatusCodes.Forbidden:
      return '/assets/error/error-403.svg'
    case ErrorStatusCodes.NotFound:
      return '/assets/error/error-404.svg'
    case ErrorStatusCodes.InternalError:
    default:
      return '/assets/error/error-500.svg'
  }
})
</script>

<template>
  <component
    :is="authenticated ? LayoutPage : 'div'"
    :class="{ 'h-full': !authenticated }"
  >
    <LayoutMain
      class="flex grow flex-col items-center justify-center gap-4 bg-blue-50 dark:bg-gray-800"
    >
      <img width="540" :alt="$t('Error')" :src="errorImage" />
      <h1 class="text-center text-xl leading-snug text-black dark:text-white">
        {{ $t(errorOptions.title) }}
      </h1>
      <CommonLabel class="mx-auto max-w-prose text-center" tag="p">
        {{
          $t(errorOptions.message, ...(errorOptions.messagePlaceholder || []))
        }}
      </CommonLabel>
      <CommonLabel
        v-if="errorOptions.route"
        class="mx-auto max-w-prose text-center"
        tag="p"
      >
        {{ errorOptions.route }}
      </CommonLabel>
      <CommonLink v-if="!authenticated" link="/login" size="medium">
        {{ $t('Please proceed to login') }}
      </CommonLink>
    </LayoutMain>
  </component>
</template>
