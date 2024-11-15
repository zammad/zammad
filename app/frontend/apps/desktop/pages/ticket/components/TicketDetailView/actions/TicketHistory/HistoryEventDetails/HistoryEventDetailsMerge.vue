<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { EventActionContent } from '../types'

interface Props {
  changes: EventActionContent
}

const { changes } = defineProps<Props>()
</script>

<template>
  <span>
    <CommonLink
      v-if="changes.link"
      :link="changes.link"
      open-in-new-tab
      internal
      class="text-blue-800 hover:underline"
      size="medium"
    >
      {{ changes.details }}
    </CommonLink>

    <CommonLabel
      v-if="changes.description"
      class="text-stone-200 ltr:ml-1 rtl:mr-1 dark:text-neutral-400"
      >{{ $t(changes.description) }}</CommonLabel
    >
  </span>
</template>
