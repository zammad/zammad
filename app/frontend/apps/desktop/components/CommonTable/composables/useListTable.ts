// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toRef } from 'vue'
import { useRouter } from 'vue-router'

import type { EnumOrderDirection } from '#shared/graphql/types.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { ObjectWithId } from '#shared/types/utils.ts'

import type { ListTableProps } from '#desktop/components/CommonTable/types'

export const useListTable = <T>(
  props: ListTableProps<T>,
  emit: (evt: 'sort', args_0: string, args_1: EnumOrderDirection) => void,
  getLink: (item: ObjectWithId) => string,
) => {
  const userId = toRef(useSessionStore(), 'userId')

  const storageKeyId = computed(() => `${userId.value}-table-headers-${props.tableId}`)

  const loadMore = async () => {
    await props.onLoadMore?.()
  }

  const resort = (column: string, direction: EnumOrderDirection) => {
    emit('sort', column, direction)
  }

  const goToItemLinkColumn = {
    internal: true,
    getLink,
  }

  const router = useRouter()

  const goToItem = (item: ObjectWithId) => router.push(getLink(item))

  return {
    goToItem,
    goToItemLinkColumn,
    loadMore,
    resort,
    storageKeyId,
  }
}
