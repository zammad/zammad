<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import LayoutTaskbarTabContent from '#desktop/components/layout/LayoutTaskbarTabContent.vue'

import KnowledgeBaseAnswerEditContent from '../components/KnowledgeBaseAnswerEdit/KnowledgeBaseAnswerEditContent.vue'
import { useKnowledgeBaseAnswerEditView } from '../composables/useKnowledgeBaseAnswerEditView.ts'

interface Props {
  localeCode: string
  answerInternalId: string
}

// Access to the answer itself is settled by the route meta (`knowledge_base.editor`, the active
//   knowledge base, and the taskbar tab's own per-record entity access - see routes.ts and
//   LayoutTaskbarTabContent). What is left for this guard is the locale: a URL naming one the
//   knowledge base does not have, shared with the create view (useKnowledgeBaseLocaleGuard).
defineOptions({
  beforeRouteEnter(to) {
    return useKnowledgeBaseAnswerEditView().checkKnowledgeBaseAnswerEditRoute(to)
  },
  beforeRouteUpdate(to) {
    return useKnowledgeBaseAnswerEditView().checkKnowledgeBaseAnswerEditRoute(to)
  },
})

defineProps<Props>()
</script>

<template>
  <LayoutTaskbarTabContent>
    <KnowledgeBaseAnswerEditContent
      :locale-code="localeCode"
      :answer-internal-id="answerInternalId"
    />
  </LayoutTaskbarTabContent>
</template>
