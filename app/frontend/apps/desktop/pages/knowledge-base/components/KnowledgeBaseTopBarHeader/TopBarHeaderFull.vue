<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { DropdownItem } from '#desktop/components/CommonDropdown/types.ts'

import { HEADER_CONTENT_OUTER_CLASSES, HEADER_CONTENT_WIDTH_CLASSES } from './headerClasses.ts'
import TopBarHeaderRow from './TopBarHeaderRow.vue'
import { type HeaderContentWidth, type TopBarHeaderProps } from './types.ts'

const props = withDefaults(
  defineProps<TopBarHeaderProps & { copyLabel?: string; contentWidth?: HeaderContentWidth }>(),
  {
    contentWidth: 'wide',
  },
)

const contentWidthClass = computed(() => HEADER_CONTENT_WIDTH_CLASSES[props.contentWidth])
const contentOuterClass = computed(() => HEADER_CONTENT_OUTER_CLASSES[props.contentWidth])

const selectedLocale = defineModel<DropdownItem>('selectedLocale')
</script>

<template>
  <header
    class="grid w-full grid-cols-[1fr_min-content] gap-x-2 gap-y-2.5 border-b border-neutral-100 bg-neutral-50/80 px-5.5 py-3 backdrop-blur-2xs dark:border-gray-900 dark:bg-gray-500/80"
  >
    <TopBarHeaderRow v-bind="$props" v-model:selected-locale="selectedLocale" variant="full">
      <template #stepper>
        <slot name="stepper" />
      </template>
    </TopBarHeaderRow>

    <!-- No title row while a node is being created: there the breadcrumb's last item is the
         heading, and it follows the title field as it is typed. -->
    <div v-if="title" class="col-span-2 flex items-center" :class="contentOuterClass">
      <CommonLabel
        class="mx-auto w-full text-xl font-medium text-black dark:text-white"
        :class="contentWidthClass"
        tag="h2"
      >
        {{ title }}
      </CommonLabel>
    </div>

    <div v-if="$slots.details" class="col-span-2" :class="contentOuterClass">
      <div class="mx-auto w-full" :class="contentWidthClass">
        <slot name="details" />
      </div>
    </div>
  </header>
</template>
