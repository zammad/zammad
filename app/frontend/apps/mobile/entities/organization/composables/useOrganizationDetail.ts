// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useObjectAttributes } from '@shared/entities/object-attributes/composables/useObjectAttributes'
import type {
  OrganizationUpdatesSubscriptionVariables,
  OrganizationUpdatesSubscription,
} from '@shared/graphql/types'
import { EnumObjectManagerObjects } from '@shared/graphql/types'
import { QueryHandler } from '@shared/server/apollo/handler'
import { computed, nextTick, ref, watch } from 'vue'
import { useOrganizationLazyQuery } from '../graphql/queries/organization.api'
import { OrganizationUpdatesDocument } from '../graphql/subscriptions/organizationUpdates.api'

export const useOrganizationDetail = () => {
  const internalId = ref(0)

  const organizationQuery = new QueryHandler(
    useOrganizationLazyQuery(
      () => ({
        organizationInternalId: internalId.value,
        membersCount: 3,
      }),
      () => ({ enabled: internalId.value > 0 }),
    ),
  )

  const loadOrganization = (id: number) => {
    internalId.value = id
    nextTick(() => {
      organizationQuery.load()
    })
  }

  const organizationResult = organizationQuery.result()
  const loading = organizationQuery.loading()

  const organization = computed(() => organizationResult.value?.organization)

  const loadAllMembers = () => {
    const organizationInternalId = organization.value?.internalId
    if (!organizationInternalId) {
      return
    }

    organizationQuery.refetch({
      organizationInternalId,
      membersCount: null,
    })
  }

  const { attributes: objectAttributes } = useObjectAttributes(
    EnumObjectManagerObjects.Organization,
  )

  watch(
    () => organization.value?.id,
    (organizationId) => {
      if (!organizationId) {
        return
      }

      organizationQuery.subscribeToMore<
        OrganizationUpdatesSubscriptionVariables,
        OrganizationUpdatesSubscription
      >({
        document: OrganizationUpdatesDocument,
        variables: {
          organizationId,
        },
      })
    },
    { immediate: true },
  )

  return {
    loading,
    organizationQuery,
    organization,
    objectAttributes,
    loadOrganization,
    loadAllMembers,
  }
}
