// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { KnowledgeBaseAnswer } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<KnowledgeBaseAnswer> => {
  return {
    __typename: 'KnowledgeBaseAnswer',
    // Empty rather than generated: a translation carries a back reference to its answer, so a
    //   listing of answers would otherwise generate a handful of files per answer twice over and
    //   trip the mocker's cap on generated ids for one type. Specs that are about files say so.
    attachments: [],
    // Empty rather than generated, and not only to keep it small: the backend derives one schedule
    //   per publication state (CanBePublished#visibility_schedules iterates the states), so
    //   `visibility` is unique across the list and the sidebar section keys its rows by it. A
    //   generated list repeats enum values, which renders duplicate keys - a Vue warning that fails
    //   whichever example happened to draw them. Specs that are about schedules pass their own.
    visibilitySchedules: [],
    // Cut like `KnowledgeBaseLocale` cuts its own back references: an answer is reachable through
    //   its translation (`KnowledgeBaseAnswerTranslation.answer`, which the taskbar, search and
    //   notification documents all select), and generating a translation from here walks straight
    //   back into another answer until the mocker trips its cap on generated ids for one type.
    //   Every spec that renders an answer names its translation - that is where the title lives.
    translation: null,
    category: null,
    archivedBy: null,
    internalBy: null,
    publishedBy: null,
  }
}
