<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
defineProps<{
  data?: unknown
}>()

defineEmits<{
  (event: 'redirect', url: string): void
}>()
</script>

<template>
  <div class="mb-7 text-center text-sm">
    <CommonLabel>
      {{ $t('The two-factor authentication is not configured yet.') }}
    </CommonLabel>
  </div>
  <div class="mb-7 text-center text-sm">
    <CommonLink link="/#">
      {{ $t('Click here to set up a two-factor authentication method.') }}
      <CommonIcon
        class="inline align-baseline"
        name="box-arrow-up-right"
        size="xs"
      />
    </CommonLink>
  </div>
</template>
