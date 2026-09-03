<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
defineEmits<{
  add: []
}>()
</script>

<template>
  <li>
    <CommonLink
      class="flex h-44.25 w-full flex-col items-center justify-center rounded-xl! bg-blue-200 p-3 hover:outline-1 hover:outline-blue-600 dark:bg-gray-500 hover:dark:outline-blue-900"
      link="#"
      role="button"
      @click.prevent="$emit('add')"
      @keydown.space.prevent="$emit('add')"
    >
      <CommonLabel prefix-icon="plus-square-fill" size="large" class="text-blue-800!">
        {{ $t('Add category') }}
      </CommonLabel>
    </CommonLink>
  </li>
</template>
