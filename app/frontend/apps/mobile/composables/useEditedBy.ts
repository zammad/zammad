// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { userDisplayName } from '#shared/entities/user/utils/getUserDisplayName.ts'
import { i18n } from '#shared/i18n.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import type { Ref } from 'vue'

interface Author {
  id: string
  firstname?: Maybe<string>
  lastname?: Maybe<string>
  fullname?: Maybe<string>
}

interface Entity {
  updatedAt?: string
  updatedBy?: Maybe<Author>
}

export const useEditedBy = (entity: Ref<Entity>) => {
  const session = useSessionStore()
  const author = computed(() => {
    const { updatedBy } = entity.value
    if (!updatedBy) return ''

    return userDisplayName(updatedBy)
  })

  const date = computed(() => {
    const { updatedAt } = entity.value
    if (!updatedAt) return ''
    return i18n.relativeDateTime(updatedAt)
  })

  const stringUpdated = computed(() => {
    if (!date.value) return ''
    if (entity.value.updatedBy?.id === session.user?.id) {
      return i18n.t('edited %s by me', date.value)
    }
    if (!author.value) return i18n.t('edited %s', date.value)
    return i18n.t('edited %s by %s', date.value, author.value)
  })

  return {
    author,
    date,
    stringUpdated,
  }
}
