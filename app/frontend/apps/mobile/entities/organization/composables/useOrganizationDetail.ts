// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useObjectAttributes } from '@shared/entities/object-attributes/composables/useObjectAttributes'
import { useErrorHandler } from '@shared/errors/useErrorHandler'
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
  const { createQueryErrorHandler } = useErrorHandler()

  const organizationQuery = new QueryHandler(
    useOrganizationLazyQuery(
      () => ({
        organizationInternalId: internalId.value,
        membersCount: 3,
      }),
      () => ({ enabled: internalId.value > 0 }),
    ),
    {
      errorCallback: createQueryErrorHandler({
        notFound: __(
          'Organization with specified ID was not found. Try checking the URL for errors.',
        ),
        forbidden: __(
          'You have insufficient rights to view this organization.',
        ),
      }),
    },
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
