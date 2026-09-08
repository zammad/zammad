<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { KnowledgeBaseAnswerTranslation } from '#shared/graphql/types.ts'

import KnowledgeBaseAnswerPopoverWithTrigger from '#desktop/components/KnowledgeBase/KnowledgeBaseAnswer/KnowledgeBaseAnswerPopoverWithTrigger.vue'
import KnowledgeBaseAnswerIcon from '#desktop/components/KnowledgeBase/KnowledgeBaseAnswerIcon/KnowledgeBaseAnswerIcon.vue'
import { getKnowledgeBaseAnswerLink } from '#desktop/entities/knowledge-base/utils/knowledgeBaseAnswerLink.ts'

import type { QuickSearchPluginProps } from '../../types.ts'

const props = defineProps<QuickSearchPluginProps>()

// The searchable unit is the translation, not the answer - so that is what the group lists, and
//   what carries the title and the locale the link and the popover are built from.
const translation = computed(() => props.item as KnowledgeBaseAnswerTranslation)

// Sends anyone who can browse a knowledge base to the answer view in Zammad - customers and agents
//   without a knowledge base permission included, whenever it is publicly available. The public
//   help site stays the fallback for an instance with no browsable knowledge base at all.
const link = computed(() => getKnowledgeBaseAnswerLink(translation.value))

// The popover loads by answer id rather than being handed this translation: the group's selection
//   is deliberately small, and fetching the popover's fragment for ten items on every debounced
//   keystroke to render something the user may never open is exactly what it avoids.
const answerId = computed(() => translation.value.answer.id)

const locale = computed(() => translation.value.kbLocale.systemLocale.locale)
</script>

<template>
  <KnowledgeBaseAnswerPopoverWithTrigger
    :answer-id="answerId"
    :locale="locale"
    :trigger-link="link"
    :popover-config="{ orientation: 'right' }"
    z-index="52"
    class="group/item flex grow items-center gap-2 rounded-md px-2 py-3 text-neutral-400 hover:bg-blue-900 hover:no-underline!"
    trigger-link-active-class="outline-2! outline-offset-1! outline-blue-800! hover:outline-blue-800!"
  >
    <KnowledgeBaseAnswerIcon show-tooltip :visibility="translation.visibility" size="tiny" />
    <CommonLabel class="block! truncate group-hover/item:text-white">
      {{ translation.title }}
    </CommonLabel>
  </KnowledgeBaseAnswerPopoverWithTrigger>
</template>
