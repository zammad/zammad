<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useUserTaskbarTabLink } from '#desktop/composables/useUserTaskbarTabLink.ts'

import type { UserTaskbarTabEntityProps } from './types.ts'

defineProps<UserTaskbarTabEntityProps>()

const { tabLinkInstance } = useUserTaskbarTabLink()
</script>

<template>
  <CommonLink
    v-if="taskbarTabLink"
    ref="tabLinkInstance"
    v-tooltip="$t('This object could not be found.')"
    class="flex grow gap-2 rounded-md px-2 py-3 hover:no-underline focus-visible:rounded-md focus-visible:outline-none group-hover/tab:bg-blue-600 group-hover/tab:dark:bg-blue-900"
    :link="taskbarTabLink"
    exact-active-class="!bg-blue-800 text-white"
    internal
  >
    <CommonIcon
      name="x-lg"
      size="small"
      class="shrink-0 text-red-500"
      decorative
    />

    <CommonLabel
      class="-:text-gray-300 -:dark:text-neutral-400 block truncate group-hover/tab:text-white group-focus-visible/link:text-white"
    >
      {{ $t('Not found') }}
    </CommonLabel>
  </CommonLink>
</template>

<style scoped>
.router-link-active span {
  @apply text-white;
}
</style>
