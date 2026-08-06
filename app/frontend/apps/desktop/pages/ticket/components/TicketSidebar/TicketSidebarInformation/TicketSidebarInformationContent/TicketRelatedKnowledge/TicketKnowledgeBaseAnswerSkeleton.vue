<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script lang="ts" setup>
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

interface Props {
  label?: string
}

defineProps<Props>()
</script>

<template>
  <li
    :aria-label="label ? $t(label) : undefined"
    class="flex h-9 list-none items-center gap-1.5 px-1.5 ltr:pr-1.5 rtl:pl-1.5"
  >
    <CommonSkeleton alternative-background rounded class="size-5 shrink-0" />
    <CommonSkeleton alternative-background class="h-4 w-32" />
  </li>
</template>
