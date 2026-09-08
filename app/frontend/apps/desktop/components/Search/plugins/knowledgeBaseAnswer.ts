// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumSearchableModels } from '#shared/graphql/types.ts'

import KnowledgeBaseAnswerTable from '#desktop/components/KnowledgeBase/KnowledgeBaseAnswerTable.vue'
import { useKnowledgeBaseAccess } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseAccess.ts'

import KnowledgeBaseAnswer from '../QuickSearch/entities/KnowledgeBaseAnswer.vue'

import type { SearchPlugin } from '../types.ts'

export default <SearchPlugin>{
  name: EnumSearchableModels.KnowledgeBaseAnswerTranslation,
  label: __('Knowledge base answer'),
  priority: 400,
  quickSearchResultLabel: __('Found knowledge base answers'),
  quickSearchComponent: KnowledgeBaseAnswer,
  quickSearchResultKey: 'quickSearchKnowledgeBaseAnswers',

  // Gated on `show` rather than on `permissions`, and deliberately: `canBrowse` is
  //   `kb_active_publicly || (kb_active && knowledge_base.*)`, which is both "a knowledge base is
  //   enabled and in use" and "no dedicated setting to switch this off". A `permissions` list
  //   cannot express it, because customers hold no knowledge base permission at all and are still
  //   meant to see published answers here.
  show: () => useKnowledgeBaseAccess().canBrowse.value,

  // No object manager attributes for this entity, so no advanced-filter UI either.
  filtersDisabled: true,
  detailSearchHeaders: ['title', 'visibility', 'updated_at'],
  detailSearchComponent: KnowledgeBaseAnswerTable,
}
