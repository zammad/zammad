<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, toRef } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useOnlineNotificationSeen } from '#shared/composables/useOnlineNotificationSeen.ts'
import { useUserDetail } from '#shared/entities/user/composables/useUserDetail.ts'
import { useErrorHandler } from '#shared/errors/useErrorHandler.ts'

import CommonButtonGroup from '#mobile/components/CommonButtonGroup/CommonButtonGroup.vue'
import type { CommonButtonOption } from '#mobile/components/CommonButtonGroup/types.ts'
import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'
import CommonOrganizationsList from '#mobile/components/CommonOrganizationsList/CommonOrganizationsList.vue'
import CommonTicketStateList from '#mobile/components/CommonTicketStateList/CommonTicketStateList.vue'
import { useHeader } from '#mobile/composables/useHeader.ts'
import { useOrganizationTicketsCount } from '#mobile/entities/organization/composables/useOrganizationTicketsCount.ts'
import { useUserEdit } from '#mobile/entities/user/composables/useUserEdit.ts'
import { useUsersTicketsCount } from '#mobile/entities/user/composables/useUserTicketsCount.ts'

interface Props {
  internalId: number
}

const props = defineProps<Props>()

const { createQueryErrorHandler } = useErrorHandler()

const errorCallback = createQueryErrorHandler({
  notFound: __(
    'User with specified ID was not found. Try checking the URL for errors.',
  ),
  forbidden: __('You have insufficient rights to view this user.'),
})

const {
  user,
  userQuery,
  loading,
  objectAttributes,
  secondaryOrganizations,
  loadAllSecondaryOrganizations,
} = useUserDetail(toRef(props, 'internalId'), errorCallback)

useOnlineNotificationSeen(user)

const { openEditUserDialog } = useUserEdit()

useHeader({
  title: __('User'),
  backUrl: '/',
  actionTitle: __('Edit'),
  actionHidden: computed(() => user.value == null || !user.value.policy.update),
  refetch: computed(() => user.value != null && userQuery.loading().value),
  onAction() {
    if (!user.value || !user.value.policy.update) return
    openEditUserDialog(user.value)
  },
})

enum TicketLinksState {
  User = 'user',
  Organization = 'organization',
}

const ticketView = ref(TicketLinksState.User)

const ticketButtons = computed<CommonButtonOption[]>(() => {
  if (!user.value?.organization) return []
  return [
    {
      label: __('Their tickets'),
      value: TicketLinksState.User,
      controls: `tab-${TicketLinksState.User}`,
    },
    {
      label: __('Organization tickets'),
      value: TicketLinksState.Organization,
      controls: `tab-${TicketLinksState.Organization}`,
    },
  ]
})

const { getTicketData: getOrganizationTicketsData } =
  useOrganizationTicketsCount()
const { getTicketData: getUserTicketsData } = useUsersTicketsCount()

const ticketsData = computed(() => {
  if (!user.value) return null

  if (ticketView.value === TicketLinksState.User) {
    return getUserTicketsData(user.value)
  }

  const { organization } = user.value

  if (!organization) return null

  return getOrganizationTicketsData(organization)
})
</script>

<template>
  <div v-if="user" class="px-4">
    <div class="flex flex-col items-center justify-center py-6">
      <div>
        <CommonUserAvatar :entity="user" size="xl" />
      </div>
      <div class="mt-2 line-clamp-3 text-center text-xl font-bold">
        {{ user.fullname }}
      </div>
      <CommonLink
        v-if="user.organization"
        data-test-id="organization-link"
        :link="`/organizations/${user.organization.internalId}`"
        class="text-blue text-center text-base"
      >
        {{ user.organization.name }}
      </CommonLink>
    </div>

    <ObjectAttributes
      :attributes="objectAttributes"
      :object="user"
      :skip-attributes="['firstname', 'lastname']"
    />

    <CommonOrganizationsList
      :organizations="secondaryOrganizations.array"
      :total-count="secondaryOrganizations.totalCount"
      :disable-show-more="loading"
      :label="__('Secondary organizations')"
      @show-more="loadAllSecondaryOrganizations()"
    />

    <CommonTicketStateList
      v-if="ticketsData"
      :id="`tab-${ticketView}`"
      :create-link="ticketsData.createLink"
      :create-label="ticketsData.createLabel"
      :counts="ticketsData.count"
      :tickets-link-query="ticketsData.query"
      role="tabpanel"
      aria-live="polite"
    >
      <template #before-fields>
        <CommonButtonGroup
          v-if="ticketButtons.length"
          v-model="ticketView"
          as="tabs"
          class="py-2"
          :options="ticketButtons"
        />
      </template>
    </CommonTicketStateList>
  </div>
  <CommonLoader v-else :loading="loading" />
</template>
