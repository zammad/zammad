<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
interface Props {
  subject: string
  to?: Maybe<string>
}

defineProps<Props>()
</script>

<template>
  <div
    class="rounded-lg border border-current p-3 text-center text-neutral-500"
  >
    <CommonLabel>&quot;{{ subject }}&quot;</CommonLabel>
    <template v-if="to">
      -&gt;
      <CommonLabel>&quot;{{ to }}&quot;</CommonLabel>
    </template>
  </div>
</template>
