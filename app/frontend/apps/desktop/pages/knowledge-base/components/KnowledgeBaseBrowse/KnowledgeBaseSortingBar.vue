<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { EnumKnowledgeBaseSortingMode } from '#shared/graphql/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonTabGroup from '#desktop/components/CommonTabs/CommonTabGroup/CommonTabGroup.vue'
import type { Tab } from '#desktop/components/CommonTabs/types.ts'

import type { KnowledgeBaseSortingMode } from '../../types.ts'

interface Props {
  dirty?: boolean
  saving?: boolean
}

defineProps<Props>()

const emit = defineEmits<{
  save: []
  cancel: []
}>()

const sortingMode = defineModel<KnowledgeBaseSortingMode>({ required: true })

// The keys are the schema's own mode values, so the picked tab *is* what the reorder mutations
//   are given.
const tabs = computed<Tab[]>(() => [
  {
    key: EnumKnowledgeBaseSortingMode.Alphabetical,
    label: __('Sort alphabetically'),
    icon: 'sort-alpha-down',
  },
  { key: EnumKnowledgeBaseSortingMode.Manual, label: __('Sort by drag & drop'), icon: 'list' },
  {
    key: EnumKnowledgeBaseSortingMode.LastUpdate,
    label: __('Sort by latest updates'),
    icon: 'clock-history',
  },
])
</script>

<!-- Rendered straight into the layout's bottom bar, which is the row: it brings the frame, the
     height and the spacing, so this is only its contents.

     `@container`, because the modes are responsive to the room this row gives them rather than to
     the window: CommonTabGroup keeps its labels behind a container query, and the layout's bottom
     bar declares no container of its own - which leaves every mode a bare icon at any window size.
     The other tab groups bring the same wrapper along (see SearchControls.vue).

     `label-breakpoint`, because this row is not the strip: it also carries the two actions and the
     spacer that centers the modes between them, so by the width the labels of three whole
     sentences need, the strip itself has long since run out of room and started scrolling. Well
     above the default, which suits a strip that has a row to itself. Below it the modes are their
     icons alone, each named by the tooltip CommonTabGroup gives an icon-only tab.

     The leading spacer is what centers the modes in the row rather than between the actions and
     the edge, which would shift them with every translation. It goes once the row is too narrow
     to center anything, leaving the modes the full width to scroll in. -->
<template>
  <div class="@container flex w-full items-center gap-4">
    <div class="hidden flex-1 @lg:block" />

    <CommonTabGroup
      v-model="sortingMode"
      :tabs="tabs"
      :label="$t('Sorting mode')"
      size="medium"
      label-breakpoint="4xl"
      class="max-w-xl min-w-0"
    />

    <div class="flex shrink-0 items-center gap-4 @lg:flex-1 @lg:justify-end">
      <CommonButton size="large" variant="secondary" :disabled="saving" @click="emit('cancel')">
        {{ $t('Cancel') }}
      </CommonButton>

      <CommonButton
        size="large"
        variant="submit"
        :disabled="!dirty || saving"
        @click="emit('save')"
      >
        {{ $t('Save') }}
      </CommonButton>
    </div>
  </div>
</template>
