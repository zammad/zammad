<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

const emit = defineEmits<{
  add: []
}>()
</script>

<!-- A list item, not a sibling of the list: the answer list renders inside a CommonLoader, whose
     slot goes through a <Transition> and therefore takes a single root element. -->
<template>
  <li class="flex h-12.5 items-center justify-center rounded-xl bg-blue-200 px-3 dark:bg-gray-500">
    <!-- `medium`, unlike the add-category button: that one fills a tile of the category grid,
         while this row sits among the answer cards and has to keep their height. -->
    <CommonButton
      variant="secondary"
      size="medium"
      prefix-icon="plus-square-fill"
      no-truncate
      class="whitespace-nowrap"
      @click="emit('add')"
    >
      {{ $t('Add answer') }}
    </CommonButton>
  </li>
</template>
