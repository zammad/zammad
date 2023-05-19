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
  <div class="my-1 rounded-xl bg-red px-4 py-2 text-center text-white">
    <p>{{ $t('The two-factor authentication is not configured yet.') }}</p>
    <CommonLink link="/#" class="text-white underline">
      {{ $t('Click here to set up a two-factor authentication method.') }}
    </CommonLink>
  </div>
</template>
