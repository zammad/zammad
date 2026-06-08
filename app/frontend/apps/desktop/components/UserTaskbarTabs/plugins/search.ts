// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { omit } from 'lodash-es'
import { stringifyQuery } from 'vue-router'

import { TicketTaskbarTabAttributesFragmentDoc } from '#shared/entities/ticket/graphql/fragments/ticketTaskbarTabAttributes.api.ts'
import { EnumTaskbarEntity, type UserTaskbarItemEntitySearch } from '#shared/graphql/types.ts'

import type { UserTaskbarTabPlugin } from '#desktop/components/UserTaskbarTabs/types.ts'

import Search from '../Search/Search.vue'

const entityType = 'Search'

export default <UserTaskbarTabPlugin>{
  type: EnumTaskbarEntity.Search,
  component: Search,
  entityType,
  entityDocument: TicketTaskbarTabAttributesFragmentDoc,
  buildEntityTabKey: () => entityType,
  buildTaskbarTabEntityId: () => undefined,
  buildTaskbarTabParams: (route) => ({
    query: route.params.searchTerm,
    model: route.query.entity,
    filters: stringifyQuery(omit(route.query, ['entity'])),
  }),
  buildTaskbarTabLink: (entity: UserTaskbarItemEntitySearch) => {
    const { query, model, filters } = entity

    let url = '/search'
    if (query) url += `/${query}`
    if (model) url += `?entity=${model}`
    if (filters) {
      url += `${model ? '&' : '?'}${filters}`
    }

    return encodeURI(url)
  },
  confirmTabRemove: true,
}
