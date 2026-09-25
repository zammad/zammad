<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
defineProps<{
  isSidebar?: boolean
}>()
</script>

<template>
  <!-- The sidebar variant drops the text for the icon alone, so the tooltip supplies the
    name, as aria-label and on hover or touch; role="img" is what gets it announced on a span. -->
  <CommonBadge
    v-tooltip="isSidebar ? $t('Maybe') : undefined"
    class="shrink-0"
    variant="warning"
    :size="isSidebar ? 'circle' : 'small'"
    role="img"
    :aria-label="$t('Maybe')"
  >
    <CommonLabel
      class="text-yellow-700! dark:text-yellow-300!"
      prefix-icon="person-maybe"
      size="small"
      >{{ isSidebar ? undefined : $t('Maybe') }}</CommonLabel
    >
  </CommonBadge>
</template>
