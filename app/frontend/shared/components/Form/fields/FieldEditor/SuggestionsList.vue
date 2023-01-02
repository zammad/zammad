<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'
import type { SuggestionKeyDownProps } from '@tiptap/suggestion'
import useNavigateOptions from './useNavigateOptions'
import type {
  MentionKnowledgeBaseItem,
  MentionTextItem,
  MentionType,
  MentionUserItem,
} from './types'

type PossibleItem = MentionUserItem | MentionKnowledgeBaseItem | MentionTextItem

interface Props {
  items: PossibleItem[]
  type: MentionType
  command: (item: PossibleItem) => void
}

const props = defineProps<Props>()

const isKnowledgeBaseItem = (
  item: unknown,
): item is MentionKnowledgeBaseItem => {
  return props.type === 'knowledge-base'
}

const isUserItem = (item: unknown): item is MentionUserItem => {
  return props.type === 'user'
}

const isTextItem = (item: unknown): item is MentionTextItem => {
  return props.type === 'text'
}

const { selectItem, selectedIndex, onKeyDown } = useNavigateOptions(
  toRef(props, 'items'),
  (item) => props.command(item as MentionUserItem),
)

defineExpose({
  onKeyDown: (props: SuggestionKeyDownProps) => {
    return onKeyDown(props.event)
  },
})
</script>

<template>
  <ul
    v-if="items.length"
    class="max-h-64 overflow-auto rounded bg-gray-300 text-white"
    :data-test-id="`mention-${type}`"
    role="listbox"
  >
    <li
      v-for="(item, index) in items"
      :id="`mention-${index}`"
      :key="item.id"
      class="cursor-pointer py-2 px-6 hover:bg-gray-400"
      :class="{ 'bg-gray-400': selectedIndex === index }"
      role="option"
      @click="selectItem(index)"
      @keydown.space.prevent="selectItem(index)"
    >
      <template v-if="isKnowledgeBaseItem(item)">
        <div class="text-sm">
          {{ item.categoryTreeTranslation.map((c) => c.title).join(' ') }}
        </div>
        <div>{{ item.title }}</div>
      </template>
      <div
        v-else-if="isTextItem(item)"
        class="flex flex-row items-center gap-2"
      >
        <div>
          {{ item.name }}
        </div>
        <div
          v-if="item.keywords"
          class="rounded border border-solid border-gray-150 px-1 text-sm"
        >
          {{ item.keywords }}
        </div>
      </div>
      <template v-else-if="isUserItem(item)">
        {{ item.fullname }}
        {{ item.email ? `<${item.email}>` : '' }}
      </template>
    </li>
  </ul>
  <div v-else class="rounded bg-gray-300 py-1 px-6 text-white">
    {{ $t('No results found') }}
  </div>
</template>
