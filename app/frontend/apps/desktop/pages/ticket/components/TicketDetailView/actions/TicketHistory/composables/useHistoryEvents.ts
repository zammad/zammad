// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { kebabCase } from 'lodash-es'

import type {
  HistoryRecordEvent,
  HistoryRecordIssuer,
  User,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import { eventActionsLookup } from '../event-actions/index.ts'
import { historyEventIssuerNames } from '../utils/historyEventIssuerNames.ts'

import type { EventActionOutput } from '../types.ts'

export const useHistoryEvents = () => {
  const issuedBySystemService = (issuer: Partial<HistoryRecordIssuer>) => {
    return issuer.__typename !== 'User'
  }

  const issuedBySystemUser = (issuer: Partial<HistoryRecordIssuer>) => {
    if (issuedBySystemService(issuer)) return false

    return (issuer as User).internalId === 1
  }

  const getIssuerName = (issuer: Partial<HistoryRecordIssuer>) => {
    switch (issuer.__typename) {
      case 'User':
        if (issuedBySystemUser(issuer)) return i18n.t('System')
        return issuer.fullname
      case 'Job':
      case 'PostmasterFilter':
      case 'Trigger':
        return `${i18n.t(historyEventIssuerNames[issuer.__typename])}: ${issuer.name}`
      case 'ObjectClass':
        return `${i18n.t(historyEventIssuerNames[issuer.klass!])}: ${issuer.info}`
      default:
        return i18n.t('Unknown')
    }
  }

  const getEventOutput = (
    event: DeepPartial<HistoryRecordEvent>,
  ): EventActionOutput => {
    if (!event.action || !eventActionsLookup[kebabCase(event.action)]) {
      throw new Error(
        // eslint-disable-next-line zammad/zammad-detect-translatable-string
        'Event action is missing or not found in event actions lookup!',
      )
    }

    const module = eventActionsLookup[kebabCase(event.action)]

    const actionName =
      typeof module.actionName === 'function'
        ? module.actionName(event)
        : module.actionName

    return {
      component: module.component,
      ...module.content(event),
      actionName: kebabCase(actionName),
    }
  }

  return {
    getIssuerName,
    issuedBySystemService,
    issuedBySystemUser,
    getEventOutput,
  }
}
