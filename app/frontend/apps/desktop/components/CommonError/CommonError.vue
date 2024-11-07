<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { ErrorOptions } from '#shared/router/error.ts'
import { ErrorStatusCodes } from '#shared/types/error.ts'

export interface Props {
  options?: ErrorOptions | null
  authenticated?: boolean
}

const props = defineProps<Props>()

const errorImage = computed(() => {
  switch (props.options?.statusCode) {
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
  <img width="540" class="max-h-96" :alt="$t('Error')" :src="errorImage" />
  <h1 class="text-center text-xl leading-snug text-black dark:text-white">
    {{ $t(options?.title) }}
  </h1>
  <CommonLabel class="mx-auto max-w-prose text-center" tag="p">
    {{ $t(options?.message, ...(options?.messagePlaceholder || [])) }}
  </CommonLabel>
  <CommonLabel
    v-if="options?.route"
    class="mx-auto max-w-prose text-center"
    tag="p"
  >
    {{ options.route }}
  </CommonLabel>
  <CommonLink v-if="!authenticated" link="/login" size="medium">
    {{ $t('Please proceed to login') }}
  </CommonLink>
</template>
