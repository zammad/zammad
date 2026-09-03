<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
defineEmits<{
  add: []
}>()
</script>

<!-- A list item, not a sibling of the list: the answer list renders inside a CommonLoader, whose
     slot goes through a <Transition> and therefore takes a single root element. -->
<template>
  <li>
    <CommonLink
      class="flex h-12.5 w-full flex-col items-center justify-center rounded-xl! bg-blue-200 p-3 hover:outline-1 hover:outline-blue-600 dark:bg-gray-500 hover:dark:outline-blue-900"
      link="#"
      role="button"
      @click.prevent="$emit('add')"
      @keydown.space.prevent="$emit('add')"
    >
      <!-- `medium`, unlike the add-category card: that one fills a tile of the category grid,
         while this row sits among the answer cards and has to keep their height. -->
      <CommonLabel prefix-icon="plus-square-fill" size="medium" class="text-blue-800!">
        {{ $t('Add answer') }}
      </CommonLabel>
    </CommonLink>
  </li>
</template>
