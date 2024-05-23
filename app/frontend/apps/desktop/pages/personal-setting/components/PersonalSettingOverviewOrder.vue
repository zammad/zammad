<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import Draggable from 'vuedraggable'

export interface OverviewItem {
  id: string
  name: string
}

const localValue = defineModel<OverviewItem[]>('modelValue')
</script>

<template>
  <div v-if="localValue" class="rounded-lg bg-blue-200 dark:bg-gray-700">
    <!-- :TODO if we add proper a11y support   -->
    <!--    <span class="hidden" aria-live="assertive" >{{assistiveText}}</span>-->
    <span id="drag-and-drop-ticket-overviews" class="sr-only">
      {{ $t('Drag and drop to reorder ticket overview list items.') }}
    </span>

    <div class="flex flex-col p-1">
      <Draggable
        v-model="localValue"
        :animation="100"
        draggable=".draggable"
        role="list"
        ghost-class="invisible"
        item-key="id"
      >
        <template #item="{ element }">
          <div
            role="listitem"
            draggable="true"
            aria-describedby="drag-and-drop-ticket-overviews"
            class="draggable flex min-h-9 cursor-grab items-start gap-2.5 p-2.5 active:cursor-grabbing"
          >
            <CommonIcon
              class="fill-stone-200 dark:fill-neutral-500"
              name="grip-vertical"
              size="tiny"
            />
            <CommonLabel class="w-full text-black dark:text-white">
              {{ $t(element.name) }}
            </CommonLabel>
          </div>
        </template>
      </Draggable>
    </div>
  </div>
</template>
