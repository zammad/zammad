// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumSearchableModels } from '#shared/graphql/types.ts'

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

  // The detailed-search tab for answers is its own story
  //   (zammad/coordination-desktop-view#874), which is why this plugin has no
  //   `detailSearchHeaders` and no `detailSearchComponent`. Registering a plugin otherwise adds a
  //   tab and a count entry on its own, so the tab is suppressed until that story builds it - at
  //   which point this flag goes away rather than being switched off.
  detailSearchDisabled: true,
}
