<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
const rows = 2

const barClasses = 'animate-pulse rounded-md bg-blue-300 dark:bg-gray-800'

const cellClasses = 'flex h-10 items-center p-2.5'
</script>

<template>
  <div
    data-test-id="knowledge-base-permissions-skeleton"
    role="status"
    :aria-label="$t('Content loader')"
    class="grid w-full grid-cols-[1fr_6rem_6rem_6rem] pb-3"
  >
    <div :class="cellClasses">
      <div :class="barClasses" class="h-3 w-12"></div>
    </div>
    <div v-for="n in 3" :key="`header-${n}`" :class="cellClasses" class="justify-center">
      <div :class="barClasses" class="h-3 w-12"></div>
    </div>

    <template v-for="n in rows" :key="`row-${n}`">
      <div :class="cellClasses">
        <div :class="barClasses" class="h-3.5 w-32 max-w-full"></div>
      </div>
      <div v-for="m in 3" :key="`cell-${n}-${m}`" :class="cellClasses" class="justify-center">
        <div :class="barClasses" class="size-5 rounded-full"></div>
      </div>
    </template>
  </div>
</template>
