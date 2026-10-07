<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import useNavigateOptions from '#shared/components/Form/fields/FieldEditor/composables/useNavigateOptions.ts'
import { useSuggestionTyping } from '#shared/components/Form/fields/FieldEditor/composables/useSuggestionTyping.ts'
import type {
  MentionKnowledgeBaseRelatedItem,
  MentionKnowledgeBaseRelatedSection,
  MentionType,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import { i18n } from '#shared/i18n.ts'

import CommonDivider from '#desktop/components/CommonDivider/CommonDivider.vue'

import FieldEditorSuggestionOption from './FieldEditorSuggestionList/FieldEditorSuggestionOption.vue'

import type { PossibleItem } from './FieldEditorSuggestionList/types.ts'
import type { SuggestionKeyDownProps } from '@tiptap/suggestion'

interface Props {
  loading?: boolean
  query: string
  items: PossibleItem[]
  type: MentionType
  command: (item: PossibleItem) => void
  label: string
  placeholder: string
  listboxId: string
}

const props = defineProps<Props>()

const optionId = (index: number) => `${props.listboxId}-option-${index}`

const { selectItem, selectedIndex, onKeyDown } = useNavigateOptions(
  toRef(props, 'items'),
  (item) => props.command(item as PossibleItem),
  optionId,
)

defineExpose({
  onKeyDown: (props: SuggestionKeyDownProps) => {
    return onKeyDown(props.event)
  },
  get selectedIndex() {
    return selectedIndex.value
  },
})

// While the user is still typing (and the query debounce hasn't settled), treat
// it as loading so a stale empty result can't flash "No results found" before
// the new query's results arrive.
const isTyping = useSuggestionTyping(toRef(props, 'query'))

const emptyMessage = computed(() => {
  if (props.loading || isTyping.value) return i18n.t('Loading…')
  if (props.query) return i18n.t('No results found')
  return i18n.t(props.placeholder)
})

const relatedSectionLabels: Record<MentionKnowledgeBaseRelatedSection, string> = {
  linked: __('Linked'),
  suggested: __('Suggested knowledge'),
}

const isRelatedItem = (item: PossibleItem): item is MentionKnowledgeBaseRelatedItem =>
  'section' in item

// The section headers label groups of options and are no options themselves: the options keep
//   their index in the flat item list, which the keyboard navigation and the active descendant use.
// Decided on the items rather than the query: while the first search runs, the related answers are
//   still the ones on display.
const relatedSections = computed(() => {
  if (props.type !== 'knowledge-base' || !props.items.some(isRelatedItem)) return []

  return (['linked', 'suggested'] as const)
    .map((section) => ({
      section,
      label: relatedSectionLabels[section],
      headerId: `${props.listboxId}-section-${section}`,
      entries: props.items
        .map((item, index) => ({ item, index }))
        .filter(({ item }) => isRelatedItem(item) && item.section === section),
    }))
    .filter(({ entries }) => entries.length)
})
</script>

<template>
  <ul
    :id="listboxId"
    class="z-50 max-h-79 max-w-154 overflow-y-auto rounded-xl border border-neutral-100 bg-neutral-50 dark:border-gray-900 dark:bg-gray-500"
    :class="{ 'pb-2': relatedSections.length }"
    :data-test-id="`mention-${type}`"
    role="listbox"
    :aria-label="$t(label)"
  >
    <template v-if="relatedSections.length">
      <li class="px-4 pt-3" role="presentation">
        <CommonLabel class="inline! truncate text-muted!" size="small">
          {{ $t(placeholder) }}
        </CommonLabel>
      </li>
      <li
        v-for="(relatedSection, sectionIndex) in relatedSections"
        :key="relatedSection.section"
        role="presentation"
      >
        <CommonDivider :class="sectionIndex ? 'my-2' : 'my-3'" aria-hidden="true" />
        <div class="mb-2 px-4">
          <CommonLabel :id="relatedSection.headerId">
            {{ $t(relatedSection.label) }}
          </CommonLabel>
        </div>
        <ul role="group" :aria-labelledby="relatedSection.headerId">
          <FieldEditorSuggestionOption
            v-for="{ item, index } in relatedSection.entries"
            :id="optionId(index)"
            :key="item.id"
            :item="item"
            :type="type"
            :selected="selectedIndex === index"
            @select="selectItem(index)"
          />
        </ul>
      </li>
    </template>
    <template v-else>
      <FieldEditorSuggestionOption
        v-for="(item, index) in items"
        :id="optionId(index)"
        :key="item.id"
        :item="item"
        :type="type"
        :selected="selectedIndex === index"
        @select="selectItem(index)"
      />
      <li v-if="!items.length" class="px-4 py-2">
        <CommonLabel class="inline! truncate text-muted!">
          {{ emptyMessage }}
        </CommonLabel>
      </li>
    </template>
  </ul>
</template>
