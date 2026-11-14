// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { escape } from 'lodash-es'
import { computed, type Ref } from 'vue'

import { userDisplayName } from '#shared/entities/user/utils/getUserDisplayName.ts'
import type { OnlineNotification } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { i18n } from '#shared/i18n.ts'
import log from '#shared/utils/log.ts'

import { activityMessageBuilder } from './activityMessageBuilder/index.ts'

const actorName = (createdBy: OnlineNotification['createdBy']) => {
  if (!createdBy) return ''
  if (getIdFromGraphQLId(createdBy.id) === 1) return i18n.t('System')

  return userDisplayName(createdBy)
}

export const useActivityMessage = (activity: Readonly<Ref<OnlineNotification>>) => {
  const builder = computed(() => activityMessageBuilder[activity.value.objectName])
  if (!builder.value) {
    log.error(`Object missing ${activity.value.objectName}.`)
  }

  const message = builder.value?.messageText(
    activity.value.typeName,
    actorName(activity.value.createdBy),
    activity.value.metaObject,
  )

  const highlightedMessage = escape(message ?? '').replace(/\|(.+)\|/gm, '<b>$1</b>')

  const link = activity.value.metaObject
    ? builder.value?.path(activity.value.metaObject)
    : undefined

  if (builder.value && !message) {
    log.error(
      `Unknown action for (${activity.value.objectName}/${activity.value.typeName}), extend activityMessages() of model.`,
    )
  }

  return { link, builder, message, highlightedMessage }
}
