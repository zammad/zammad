<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { animations, parents } from '@formkit/drag-and-drop'
import { dragAndDrop } from '@formkit/drag-and-drop/vue'
import { cloneDeep, isEqual } from 'lodash-es'
import { ref, watch, useTemplateRef, type Ref } from 'vue'

import { startAndEndEventsDNDPlugin } from '#shared/utils/startAndEndEventsDNDPlugin.ts'

export interface OverviewItem {
  id: string
  name: string
  organizationShared?: boolean | null
  outOfOffice?: boolean | null
}

const localValue = defineModel<OverviewItem[]>({
  required: true,
})

const dndEndCallback = (parent: HTMLElement) => {
  const parentData = parents.get(parent)
  if (!parentData) return

  localValue.value = cloneDeep(parentData.getValues(parent))
}

const dndParentElement = useTemplateRef('dnd-parent')
const dndLocalValue = ref(localValue.value || [])

watch(localValue, (newValue) => {
  if (isEqual(dndLocalValue.value, newValue)) return

  dndLocalValue.value = cloneDeep(newValue || [])
})

dragAndDrop({
  parent: dndParentElement as Ref<HTMLElement>,
  values: dndLocalValue,
  plugins: [
    startAndEndEventsDNDPlugin(undefined, dndEndCallback),
    animations(),
  ],
  dropZoneClass: 'opacity-0',
  touchDropZoneClass: 'opacity-0',
})
</script>

<template>
  <div v-if="localValue" class="rounded-lg bg-blue-200 dark:bg-gray-700">
    <!-- :TODO if we add proper a11y support   -->
    <!--    <span class="hidden" aria-live="assertive" >{{assistiveText}}</span>-->
    <span id="drag-and-drop-ticket-overviews" class="sr-only">
      {{ $t('Drag and drop to reorder ticket overview list items.') }}
    </span>

    <ul ref="dnd-parent" class="flex flex-col p-1">
      <li
        v-for="value in dndLocalValue"
        :key="value.id"
        class="draggable flex min-h-9 cursor-grab items-start gap-2.5 p-2.5 active:cursor-grabbing"
        draggable="true"
        aria-describedby="drag-and-drop-ticket-overviews"
      >
        <CommonIcon
          class="mt-1 shrink-0 fill-stone-200 dark:fill-neutral-500"
          name="grip-vertical"
          size="tiny"
          decorative
        />
        <div class="grow">
          <CommonLabel class="inline text-black dark:text-white">
            {{ $t(value.name) }}
          </CommonLabel>
          <CommonBadge
            v-if="value.organizationShared"
            variant="info"
            class="ms-1.5"
            >{{ $t('Only when shared organization member') }}</CommonBadge
          >
          <CommonBadge v-if="value.outOfOffice" variant="info" class="ms-1.5">{{
            $t('Only when out of office replacement')
          }}</CommonBadge>
        </div>
      </li>
    </ul>
  </div>
</template>
