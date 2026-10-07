<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type {
  MentionKnowledgeBaseItem,
  MentionKnowledgeBaseRelatedItem,
  MentionTextItem,
  MentionType,
  MentionUserItem,
} from '#shared/components/Form/fields/FieldEditor/types.ts'

import type { PossibleItem } from './types.ts'

interface Props {
  id: string
  item: PossibleItem
  type: MentionType
  selected: boolean
}

defineProps<Props>()

defineEmits<{
  select: []
}>()

const getKnowledgeBaseItemBreadcrumb = (
  item: MentionKnowledgeBaseItem | MentionKnowledgeBaseRelatedItem,
) =>
  item.categoryTreeTranslation
    .reduce((acc, component, index) => {
      if (index === 0 || index === item.categoryTreeTranslation.length - 1) {
        acc.push(component.title)
      } else if (!acc.includes('…')) {
        acc.push('…') // ellipsis (…)
      }
      return acc
    }, [] as string[])
    .join(' › ') // guillemet (›)
</script>

<template>
  <!-- Options are intentionally not focusable and have no key handler: the editor keeps -->
  <!-- focus and drives selection via aria-activedescendant (ARIA combobox pattern). -->
  <!-- eslint-disable-next-line vuejs-accessibility/interactive-supports-focus, vuejs-accessibility/click-events-have-key-events -->
  <li
    :id="id"
    class="group cursor-pointer px-4 py-2 hover:bg-blue-600 dark:hover:bg-blue-900"
    :class="{ 'bg-blue-600 dark:bg-blue-900': selected }"
    role="option"
    :aria-selected="selected"
    @click="$emit('select')"
  >
    <div v-if="type === 'knowledge-base'" class="flex flex-col gap-px">
      <CommonLabel
        class="inline! truncate text-muted! group-hover:text-contrast!"
        :class="{ 'text-contrast!': selected }"
        size="small"
      >
        {{ getKnowledgeBaseItemBreadcrumb(item as MentionKnowledgeBaseItem) }}
      </CommonLabel>
      <CommonLabel
        class="inline! truncate group-hover:text-contrast"
        :class="{ 'text-contrast!': selected }"
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
        class="inline! truncate group-hover:text-contrast"
        :class="{ 'text-contrast!': selected }"
        >{{ (item as MentionTextItem).name }}</CommonLabel
      >
      <span
        v-if="(item as MentionTextItem).keywords"
        class="truncate rounded-sm bg-white p-1 font-mono text-xs text-muted group-hover:text-contrast dark:bg-black"
        :class="{ 'text-contrast!': selected }"
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
        class="inline! truncate group-hover:text-contrast"
        :class="{ 'text-contrast!': selected }"
      >
        {{ (item as MentionUserItem).fullname }}
      </CommonLabel>
      <CommonLabel
        v-if="(item as MentionUserItem).email"
        class="truncate text-muted! group-hover:text-contrast!"
        :class="{ 'text-contrast!': selected }"
      >
        – {{ (item as MentionUserItem).email }}
      </CommonLabel>
    </div>
  </li>
</template>
