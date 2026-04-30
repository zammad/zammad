<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import useNavigateOptions from '#shared/components/Form/fields/FieldEditor/composables/useNavigateOptions.ts'
import type {
  MentionKnowledgeBaseItem,
  MentionTextItem,
  MentionType,
  MentionUserItem,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import { i18n } from '#shared/i18n.ts'

import type { SuggestionKeyDownProps } from '@tiptap/suggestion'

type PossibleItem = MentionUserItem | MentionKnowledgeBaseItem | MentionTextItem

interface Props {
  loading?: boolean
  query: string
  items: PossibleItem[]
  type: MentionType
  command: (item: PossibleItem) => void
}

const props = defineProps<Props>()

const { selectItem, selectedIndex, onKeyDown } = useNavigateOptions(toRef(props, 'items'), (item) =>
  props.command(item as MentionUserItem),
)

const getKnowledgeBaseItemBreadcrumb = (item: MentionKnowledgeBaseItem) =>
  item.categoryTreeTranslation
    .reduce((acc, component, index) => {
      if (index === 0 || index === item.categoryTreeTranslation.length - 1) {
        acc.push(component.title)
      } else if (!acc.includes('…')) {
        acc.push('\u2026') // ellipsis (…)
      }
      return acc
    }, [] as string[])
    .join(' \u203A ') // guillemet (›)

defineExpose({
  onKeyDown: (props: SuggestionKeyDownProps) => {
    return onKeyDown(props.event)
  },
})

const emptyMessage = computed(() => {
  if (props.loading) return i18n.t('Loading…')
  if (props.query) return i18n.t('No results found')
  if (props.type === 'knowledge-base') return i18n.t('Start typing to search in Knowledge Base…')
  if (props.type === 'text') return i18n.t('Start typing to search for text modules…')
  if (props.type === 'user') return i18n.t('Start typing to search for users…')

  return i18n.t('Start typing to search…')
})
</script>

<template>
  <ul
    class="z-50 max-h-79 max-w-154 overflow-y-auto rounded-xl border border-neutral-100 bg-neutral-50 dark:border-gray-900 dark:bg-gray-500"
    :data-test-id="`mention-${type}`"
    role="listbox"
  >
    <li
      v-for="(item, index) in items as
        | MentionKnowledgeBaseItem[]
        | MentionTextItem[]
        | MentionUserItem[]"
      :id="`mention-${index}`"
      :key="item.id"
      class="group cursor-pointer px-4 py-2 hover:bg-blue-600 dark:hover:bg-blue-900"
      :class="{ 'bg-blue-600 dark:bg-blue-900': selectedIndex === index }"
      role="option"
      :aria-selected="selectedIndex === index"
      tabindex="0"
      @click="selectItem(index)"
      @keydown.space.prevent="selectItem(index)"
    >
      <div v-if="type === 'knowledge-base'" class="flex flex-col gap-px">
        <CommonLabel
          class="inline! truncate text-stone-200 group-hover:text-black dark:text-neutral-500 dark:group-hover:text-white"
          :class="{ 'text-black! dark:text-white!': selectedIndex === index }"
          size="small"
        >
          {{ getKnowledgeBaseItemBreadcrumb(item as MentionKnowledgeBaseItem) }}
        </CommonLabel>
        <CommonLabel
          class="inline! truncate group-hover:text-black dark:group-hover:text-white"
          :class="{ 'text-black! dark:text-white!': selectedIndex === index }"
        >
          {{ (item as MentionKnowledgeBaseItem).title }}
          {{
            (item as MentionKnowledgeBaseItem).maybeLocale
              ? `(${(item as MentionKnowledgeBaseItem).maybeLocale})`
              : ''
          }}
        </CommonLabel>
      </div>
      <div v-else-if="type === 'text'" class="flex items-center gap-2">
        <CommonLabel
          class="inline! truncate group-hover:text-black dark:group-hover:text-white"
          :class="{ 'text-black! dark:text-white!': selectedIndex === index }"
          >{{ (item as MentionTextItem).name }}</CommonLabel
        >
        <span
          v-if="(item as MentionTextItem).keywords"
          class="truncate rounded-sm bg-white p-1 font-mono text-xs text-stone-200 group-hover:text-black dark:bg-black dark:text-neutral-500 dark:group-hover:text-white"
          :class="{ 'text-black! dark:text-white!': selectedIndex === index }"
        >
          {{ (item as MentionTextItem).keywords }}
        </span>
      </div>
      <div v-else-if="type === 'user'" class="flex items-center gap-2">
        <CommonUserAvatar
          :entity="item"
          :class="{
            'opacity-30': !(item as MentionUserItem).active,
          }"
          size="xs"
        />
        <CommonLabel
          class="inline! truncate group-hover:text-black dark:group-hover:text-white"
          :class="{ 'text-black! dark:text-white!': selectedIndex === index }"
        >
          {{ (item as MentionUserItem).fullname }}
        </CommonLabel>
        <CommonLabel
          v-if="(item as MentionUserItem).email"
          class="truncate text-stone-200 group-hover:text-black dark:text-neutral-500 dark:group-hover:text-white"
          :class="{ 'text-black! dark:text-white!': selectedIndex === index }"
        >
          – {{ (item as MentionUserItem).email }}
        </CommonLabel>
      </div>
    </li>
    <li v-if="!items.length" class="px-4 py-2">
      <CommonLabel class="inline! truncate text-stone-200 dark:text-neutral-500">
        {{ emptyMessage }}
      </CommonLabel>
    </li>
  </ul>
</template>
