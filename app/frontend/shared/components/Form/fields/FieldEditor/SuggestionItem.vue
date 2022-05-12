<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'
import type { SuggestionKeyDownProps } from '@tiptap/suggestion'
import useNavigateOptions from './useNavigateOptions'
import type {
  CommandKnowledgeBaseProps,
  CommandTextProps,
  CommandUserProps,
  MentionKnowledgeBaseItem,
  MentionTextItem,
  MentionType,
  MentionUserItem,
} from './types'

interface Props {
  items: (MentionUserItem | MentionKnowledgeBaseItem | MentionTextItem)[]
  type: MentionType
  command: (
    props: CommandUserProps | CommandKnowledgeBaseProps | CommandTextProps,
  ) => void
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
  (item) => {
    if (isUserItem(item)) {
      const { id, lastname, firstname } = item
      const href = `${window.location.origin}/#user/profile/${item.id}`
      props.command({
        id,
        title: [firstname, lastname].filter(Boolean).join(' '),
        href,
      })
    }

    if (isKnowledgeBaseItem(item) || isTextItem(item)) {
      props.command(item)
    }
  },
)

defineExpose({
  onKeyDown: (props: SuggestionKeyDownProps) => {
    return onKeyDown(props.event)
  },
})
</script>

<template>
  <div
    class="max-h-64 overflow-auto rounded bg-gray-300 text-white"
    :data-test-id="`mention-${type}`"
  >
    <div
      v-for="(item, index) in items"
      :key="item.id"
      class="cursor-pointer py-2 px-6 hover:bg-gray-400"
      :class="{ 'bg-gray-400': selectedIndex === index }"
      @click="selectItem(index)"
    >
      <template v-if="isKnowledgeBaseItem(item)">
        <div class="text-sm">{{ item.category }}</div>
        <div>{{ item.title }}</div>
      </template>
      <div
        v-else-if="isTextItem(item)"
        class="flex flex-row items-center gap-2"
      >
        <div>
          {{ item.title }}
        </div>
        <div class="rounded border border-solid border-gray-150 px-1 text-sm">
          {{ item.keyword }}
        </div>
      </div>
      <template v-else-if="isUserItem(item)">
        {{ item.firstname }} {{ item.lastname }}
        {{ item.email ? `<${item.email}>` : '' }}
      </template>
    </div>
    <div v-if="!items.length" class="py-1 px-6">Nothing found...</div>
  </div>
</template>
