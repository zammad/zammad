<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { SECONDARY_ORGANIZATIONS_FETCH_COUNT } from '#shared/entities/user/composables/useUserDetail.ts'
import { useUserEntity } from '#shared/entities/user/composables/useUserEntity.ts'
import { useUserUpdatesSubscription } from '#shared/graphql/subscriptions/userUpdates.api.ts'
import type { User } from '#shared/graphql/types.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import { useUserTaskbarTab } from '#desktop/composables/useUserTaskbarTab.ts'

import type { UserTaskbarTabEntityProps } from '../types.ts'

const props = defineProps<UserTaskbarTabEntityProps<User>>()

const { isTaskbarTabLoaded, tabLinkInstance, taskbarTabActive } = useUserTaskbarTab(
  toRef(props, 'taskbarTab'),
)

const user = computed(() => props.taskbarTab.entity)

const { userDisplayName, isUserInactive } = useUserEntity(user)

new SubscriptionHandler(
  useUserUpdatesSubscription(
    () => ({
      userId: user.value!.id,
      initial: true,
      secondaryOrganizationsCount: SECONDARY_ORGANIZATIONS_FETCH_COUNT,
    }),
    () => ({
      // NB: User detail view has its own subscription handling, avoid double subscriptions.
      enabled: !!user.value?.id && !isTaskbarTabLoaded.value,
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
      :name="isUserInactive ? 'user-inactive' : 'user'"
    />
    <CommonLabel
      class="block! truncate text-gray-300 group-focus-visible/link:text-white dark:text-neutral-400 group-hover/tab:dark:text-white"
      :class="{
        'text-white!': taskbarTabActive,
      }"
    >
      {{ userDisplayName }}
    </CommonLabel>
  </CommonLink>
</template>
