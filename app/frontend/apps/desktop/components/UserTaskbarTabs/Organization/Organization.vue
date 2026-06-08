<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { useOrganizationEntity } from '#shared/entities/organization/composables/useOrganizationEntity.ts'
import { useOrganizationUpdatesSubscription } from '#shared/entities/organization/graphql/subscriptions/organizationUpdates.api.ts'
import { SECONDARY_ORGANIZATIONS_FETCH_COUNT } from '#shared/entities/user/composables/useUserDetail.ts'
import type { Organization } from '#shared/graphql/types.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import { useUserTaskbarTab } from '#desktop/composables/useUserTaskbarTab.ts'

import type { UserTaskbarTabEntityProps } from '../types.ts'

const props = defineProps<UserTaskbarTabEntityProps<Organization>>()

const { isTaskbarTabLoaded, tabLinkInstance, taskbarTabActive } = useUserTaskbarTab(
  toRef(props, 'taskbarTab'),
)

const organization = computed(() => props.taskbarTab.entity)

const { organizationDisplayName, isOrganizationInactive } = useOrganizationEntity(organization)

new SubscriptionHandler(
  useOrganizationUpdatesSubscription(
    () => ({
      organizationId: organization.value!.id,
      first: SECONDARY_ORGANIZATIONS_FETCH_COUNT,
      initial: true,
    }),
    () => ({
      // NB: Organization detail view has its own subscription handling, avoid double subscriptions.
      enabled: !!organization.value?.id && !isTaskbarTabLoaded.value,
    }),
  ),
  {
    // NB: Silence toast notifications for particular errors, these will be handled by the layout taskbar tab component.
    errorCallback: (errorHandler) =>
      errorHandler.type !== GraphQLErrorTypes.Forbidden &&
      errorHandler.type !== GraphQLErrorTypes.RecordNotFound,
  },
)
</script>

<template>
  <CommonLink
    v-if="taskbarTabLink"
    ref="tabLinkInstance"
    class="flex grow items-center gap-2 rounded-md px-2 py-3 group-hover/tab:bg-blue-600 hover:no-underline! focus-visible:rounded-md focus-visible:outline-hidden group-hover/tab:dark:bg-blue-900"
    :link="taskbarTabLink"
    :class="{
      'bg-blue-800!': taskbarTabActive,
    }"
    internal
  >
    <CommonIcon
      class="shrink-0 text-neutral-500 group-focus-visible/link:text-white!"
      :class="{
        'text-white!': taskbarTabActive,
      }"
      size="tiny"
      :name="isOrganizationInactive ? 'buildings-slash' : 'buildings'"
    />
    <CommonLabel
      class="block! truncate text-gray-300 group-focus-visible/link:text-white dark:text-neutral-400 group-hover/tab:dark:text-white"
      :class="{
        'text-white!': taskbarTabActive,
      }"
    >
      {{ organizationDisplayName }}
    </CommonLabel>
  </CommonLink>
</template>
