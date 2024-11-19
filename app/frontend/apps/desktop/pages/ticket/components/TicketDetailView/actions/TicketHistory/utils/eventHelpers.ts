// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { HistoryRecordEvent, ObjectClass } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import { eventEntityNames } from './historyEventEntityNames.ts'

export const getEntityFromObject = (
  object?: Maybe<DeepPartial<HistoryRecordEvent['object']>>,
) => {
  return (
    (object?.__typename === 'ObjectClass'
      ? (object as ObjectClass).klass
      : object?.__typename) || __('Unknown')
  )
}

export const getEntityNameFromObject = (
  object?: Maybe<DeepPartial<HistoryRecordEvent['object']>>,
) => {
  const entity = getEntityFromObject(object)

  return eventEntityNames[entity] || entity
}
