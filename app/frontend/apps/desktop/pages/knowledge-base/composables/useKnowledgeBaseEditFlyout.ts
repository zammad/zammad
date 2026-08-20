// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { openFlyout, useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'

const FLYOUT_NAME = 'knowledge-base-edit'

export const openKnowledgeBaseEditFlyout = () =>
  openFlyout(FLYOUT_NAME, {
    name: FLYOUT_NAME,
  })

export const useKnowledgeBaseEditFlyout = () => {
  useFlyout({
    name: FLYOUT_NAME,
    component: () =>
      import('#desktop/pages/knowledge-base/components/KnowledgeBaseEditFlyout/KnowledgeBaseEditFlyout.vue'),
  })

  return { openKnowledgeBaseEditFlyout }
}
