<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { DropdownItem } from '#desktop/components/CommonDropdown/types.ts'
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

import { HEADER_CONTENT_OUTER_CLASSES, HEADER_CONTENT_WIDTH_CLASSES } from './headerClasses.ts'
import TopBarHeaderRow from './TopBarHeaderRow.vue'
import { type HeaderContentWidth, type TopBarHeaderProps } from './types.ts'

const props = withDefaults(
  defineProps<
    TopBarHeaderProps & {
      copyLabel?: string
      contentWidth?: HeaderContentWidth
      // Where the create/edit forms' title field (useAnswerFormSchema.ts) teleports its input, in
      //   place of the `title` row above - a container of its own so the field keeps rendering
      //   here even though the row it replaces is otherwise conditional on `title`. Not part of
      //   TopBarHeaderProps: the compact header never showed a title row either, so there is
      //   nothing here for it to receive.
      titleFieldTarget?: string
    }
  >(),
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

    <!-- No title row while a node is being created or edited: there the breadcrumb is the
         heading (from the stored record, or from the create draft's category), and the title
         itself is a plain field - `titleFieldTarget` is where the create/edit schema teleports it
         instead. Provisional (2026-08-26): kept as a capability of its own rather than removed,
         so going back to a heading-only title later is a matter of passing `title` again, not
         rebuilding this row.

         Both render when both are given, deliberately: the container below is a teleport target
         resolved once, on mount, so making it the `v-else` of a title would let a caller that
         starts passing `title` destroy it under a form that is already teleporting into it. -->
    <div
      v-if="title || titleFieldTarget"
      class="col-span-2 flex items-center"
      :class="contentOuterClass"
    >
      <CommonLabel
        v-if="title"
        class="mx-auto w-full text-xl font-medium text-black dark:text-white"
        :class="contentWidthClass"
        tag="h2"
      >
        {{ title }}
      </CommonLabel>

      <!-- Mounted from the first render on, loading or not: the field teleported in here resolves
           this container once (`titleFieldTarget` above), so the block below only stands in for
           the field's height until the record - and with it the form - is there. -->
      <div
        v-if="titleFieldTarget"
        :id="titleFieldTarget"
        class="mx-auto w-full"
        :class="contentWidthClass"
      >
        <CommonSkeleton v-if="loading" class="h-10 w-full" />
      </div>
    </div>

    <div v-if="$slots.details || loading" class="col-span-2" :class="contentOuterClass">
      <div class="mx-auto w-full" :class="contentWidthClass">
        <div v-if="loading" class="flex gap-2.5">
          <CommonSkeleton class="h-7 w-24" rounded />
          <CommonSkeleton class="h-7 w-56" rounded />
        </div>

        <slot v-else name="details" />
      </div>
    </div>
  </header>
</template>
