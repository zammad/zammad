// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useKnowledgeBaseLocaleGuard } from './useKnowledgeBaseLocaleGuard.ts'

// Unlike the create view, the edit view mints no tab id of its own - the tab is keyed off the
//   answer id and the locale already in the URL (Taskbar.entity_key), so there is nothing left to
//   check here besides the locale.
export const useKnowledgeBaseAnswerEditView = () => {
  const { checkKnownLocale } = useKnowledgeBaseLocaleGuard()

  return { checkKnowledgeBaseAnswerEditRoute: checkKnownLocale }
}
