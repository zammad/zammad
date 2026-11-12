// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumSearchableModels } from '#shared/graphql/types.ts'

import ChatSessionListTable from '#desktop/components/Chat/ChatSessionListTable.vue'
import { useChatAccess } from '#desktop/entities/chat/composables/useChatAccess.ts'

import ChatSession from '../QuickSearch/entities/ChatSession.vue'

import type { SearchPlugin } from '../types.ts'

export default <SearchPlugin>{
  name: EnumSearchableModels.ChatSession,
  label: __('Chat session'),
  priority: 500,
  quickSearchResultLabel: __('Found chat sessions'),
  quickSearchComponent: ChatSession,
  permissions: ['chat.agent'],

  // Like the old UI, which offers the model only while the chat feature is switched on.
  show: () => useChatAccess().isChatEnabled.value,

  // No object manager attributes for this entity, so no advanced-filter UI either.
  filtersDisabled: true,
  detailSearchHeaders: ['internal_id', 'name', 'state', 'created_at'],
  detailSearchComponent: ChatSessionListTable,
}
