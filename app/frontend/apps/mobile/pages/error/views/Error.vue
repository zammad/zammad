<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { errorOptions } from '#shared/router/error.ts'
import { ErrorStatusCodes } from '#shared/types/error.ts'

import CommonBackButton from '#mobile/components/CommonBackButton/CommonBackButton.vue'

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
  <div class="flex min-h-screen flex-col px-4">
    <header class="fixed">
      <div class="grid h-16 grid-cols-[75px_auto_75px]">
        <div
          class="flex cursor-pointer items-center justify-self-start text-base"
        >
          <CommonBackButton fallback="/" />
        </div>
      </div>
    </header>
    <main class="flex grow flex-col items-center justify-center">
      <h1 class="mb-9 text-8xl font-extrabold">
        {{ errorOptions.statusCode }}
      </h1>
      <img :alt="$t('Error')" :src="errorImage" />
      <h2 class="mt-9 max-w-prose text-center text-xl font-semibold">
        {{ $t(errorOptions.title) }}
      </h2>
      <p class="text-gray mt-4 min-h-[4rem] max-w-prose text-center">
        {{
          $t(errorOptions.message, ...(errorOptions.messagePlaceholder || []))
        }}
      </p>
      <p v-if="errorOptions.route" class="text-gray max-w-prose text-center">
        {{ errorOptions.route }}
      </p>
    </main>
  </div>
</template>
