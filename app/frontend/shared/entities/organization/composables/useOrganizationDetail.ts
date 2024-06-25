// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, nextTick, ref, watch, type Ref } from 'vue'

import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import type {
  OrganizationUpdatesSubscriptionVariables,
  OrganizationUpdatesSubscription,
} from '#shared/graphql/types.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import type { GraphQLHandlerError } from '#shared/types/error.ts'

import { useOrganizationLazyQuery } from '../graphql/queries/organization.api.ts'
import { OrganizationUpdatesDocument } from '../graphql/subscriptions/organizationUpdates.api.ts'

import type { WatchQueryFetchPolicy } from '@apollo/client'

export const useOrganizationDetail = (
  organizationId?: Ref<number>,
  errorCallback?: (error: GraphQLHandlerError) => boolean,
  fetchPolicy?: WatchQueryFetchPolicy,
) => {
  const internalId = organizationId || ref(0)
  const fetchMembersCount = ref<Maybe<number>>(3)

  const organizationQuery = new QueryHandler(
    useOrganizationLazyQuery(
      () => ({
        organizationInternalId: internalId.value,
        membersCount: 3,
      }),
      () => ({ enabled: internalId.value > 0, fetchPolicy }),
    ),
    {
      errorCallback,
    },
  )

  if (internalId.value) {
    organizationQuery.load()
  }

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

    organizationQuery
      .refetch({
        organizationInternalId,
        membersCount: null,
      })
      .then(() => {
        fetchMembersCount.value = null
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
      >(() => ({
        document: OrganizationUpdatesDocument,
        variables: {
          organizationId,
          membersCount: fetchMembersCount.value,
        },
      }))
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
