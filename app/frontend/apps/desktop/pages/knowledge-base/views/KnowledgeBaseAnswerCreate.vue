<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import LayoutTaskbarTabContent from '#desktop/components/layout/LayoutTaskbarTabContent.vue'

import KnowledgeBaseAnswerCreateContent from '../components/KnowledgeBaseAnswerCreate/KnowledgeBaseAnswerCreateContent.vue'
import { useKnowledgeBaseAnswerCreateView } from '../composables/useKnowledgeBaseAnswerCreateView.ts'

interface Props {
  localeCode: string
  tabId: string
}

// Access itself is settled by the route meta (`knowledge_base.editor` plus an active knowledge
//   base); the guards make sure the URL describes a draft that can exist - a tab id, and a locale
//   the knowledge base actually has.
defineOptions({
  beforeRouteEnter(to) {
    return useKnowledgeBaseAnswerCreateView().checkKnowledgeBaseAnswerCreateRoute(to)
  },
  beforeRouteUpdate(to) {
    return useKnowledgeBaseAnswerCreateView().checkKnowledgeBaseAnswerCreateRoute(to)
  },
})

defineProps<Props>()
</script>

<template>
  <LayoutTaskbarTabContent>
    <KnowledgeBaseAnswerCreateContent :locale-code="localeCode" :tab-id="tabId" />
  </LayoutTaskbarTabContent>
</template>
