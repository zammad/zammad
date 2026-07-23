<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script lang="ts" setup>
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

interface Props {
  label?: string
}

defineProps<Props>()
</script>

<template>
  <li class="flex h-9 list-none items-center gap-1.5 px-1.5 ltr:pr-1.5 rtl:pl-1.5">
    <CommonSkeleton class="size-4 shrink-0 rounded-md" alternative-background />
    <CommonSkeleton class="h-3.5 grow rounded-md" :label="label" alternative-background />
  </li>
</template>
