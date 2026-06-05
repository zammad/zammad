<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, useTemplateRef } from 'vue'

import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useUserDetail } from '#shared/entities/user/composables/useUserDetail.ts'
import { useUserEntity } from '#shared/entities/user/composables/useUserEntity.ts'
import { useUserNoteUpdateMutation } from '#shared/entities/user/graphql/mutations/noteUpdate.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import emitter from '#shared/utils/emitter.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonSectionContainer from '#desktop/components/CommonSectionContainer/CommonSectionContainer.vue'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import CommonTabGroup from '#desktop/components/CommonTabs/CommonTabGroup/CommonTabGroup.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import UserTicketBarChart from '#desktop/components/Ticket/TicketBarChart/UserTicketBarChart.vue'
import { usePage } from '#desktop/composables/usePage.ts'
import { useScrollPosition } from '#desktop/composables/useScrollPosition.ts'
import { useTicketByCustomerUpdatesSubscription } from '#desktop/entities/ticket/graphql/subscriptions/ticketByCustomerUpdates.api.ts'

import UserDetailTopBar from './UserDetailTopBar.vue'
import UserRelatedCustomerTickets from './UserRelatedCustomerTickets.vue'

interface Props {
  internalId: string
}

const props = defineProps<Props>()

const userId = computed(() => convertToGraphQLId('User', props.internalId))

const chartInstance = useTemplateRef('chart')

const {
  user,
  loadingWithoutCachedResult,
  objectAttributes,
  secondaryOrganizations,
  fetchMoreSecondaryOrganizations,
} = useUserDetail(
  userId,
  4,
  100,
  // NB: Silence toast notifications for particular errors, these will be handled by the layout taskbar tab component.
  (errorHandler) =>
    errorHandler.type !== GraphQLErrorTypes.Forbidden &&
    errorHandler.type !== GraphQLErrorTypes.RecordNotFound,
  'cache-first',
  true, // include organization ticket counts
)

const { userDisplayName } = useUserEntity(user)

usePage({
  metaTitle: userDisplayName,
})

const contentContainerElement = useTemplateRef('content-container')

useScrollPosition(contentContainerElement)

const { hasPermission } = useSessionStore()

const customerTicketsTabs = computed(() => [
  {
    key: 'user',
    label: __('User'),
    count: (user.value.ticketsCount?.open ?? 0) + (user.value.ticketsCount?.closed ?? 0),
  },
  {
    key: 'organization',
    label: __('Organization'),
    count:
      (user.value.ticketsCount?.organizationOpen ?? 0) +
      (user.value.ticketsCount?.organizationClosed ?? 0),
  },
])

const activeCustomerTicketsTab = ref<'user' | 'organization'>('user')

const customerTicketsSubscription = new SubscriptionHandler(
  useTicketByCustomerUpdatesSubscription(
    () => ({
      customerId: userId.value,
    }),
    {
      enabled: hasPermission('ticket.agent'),
    },
  ),
)

customerTicketsSubscription.onResult(({ data }) => {
  if (!data?.ticketByCustomerUpdates.listChanged) return

  chartInstance.value?.refetchData()

  emitter.emit(`customer-ticket-list-refetch:${userId.value}`)
})
</script>

<template>
  <LayoutContent
    name="user-detail"
    no-padding
    background-variant="primary"
    content-alignment="center"
    no-scrollable
  >
    <CommonLoader class="mt-8" :loading="loadingWithoutCachedResult">
      <div ref="content-container" class="@container size-full overflow-y-auto">
        <UserDetailTopBar
          :user="user"
          :user-display-name="userDisplayName"
          :content-container-element="contentContainerElement"
        />
        <section
          class="mx-auto grid w-full max-w-5xl min-w-xs grid-cols-1 gap-6 p-3 @xl:min-w-sm @xl:grid-cols-2 @xl:p-6"
        >
          <div class="flex flex-col gap-6 self-start">
            <CommonSectionContainer
              v-if="user?.hasSecondaryOrganizations"
              :label="__('Secondary organizations')"
              no-heading
              alternative-background
            >
              <CommonSimpleEntityList
                id="user-secondary-organizations"
                :type="EntityType.Organization"
                :label="__('Secondary organizations')"
                :entity="secondaryOrganizations"
                label-size="medium"
                label-class="text-black! dark:text-white! mb-2.5"
                label-tag="h2"
                list-class="grid grid-cols-2 gap-3"
                has-popover
                no-collapse
                @load-more="fetchMoreSecondaryOrganizations"
              />
            </CommonSectionContainer>
            <ObjectAttributes
              :attributes="objectAttributes"
              :object="user"
              :skip-attributes="['firstname', 'lastname', 'organization_id', 'organization_ids']"
              :inline-editable="{ note: useUserNoteUpdateMutation }"
            />
          </div>

          <CommonSectionContainer
            v-if="
              hasPermission('ticket.agent') &&
              (user.ticketsCount?.open || user.ticketsCount?.closed)
            "
            class="w-full self-start @xl:w-fit"
            :label="__('Related tickets')"
          >
            <template v-if="user.organization">
              <CommonTabGroup
                v-model="activeCustomerTicketsTab"
                class="mb-3"
                :tabs="customerTicketsTabs"
              />
              <UserRelatedCustomerTickets
                v-show="activeCustomerTicketsTab === 'user'"
                id="tab-panel-user"
                :customer="user"
              />
              <UserRelatedCustomerTickets
                v-show="activeCustomerTicketsTab === 'organization'"
                id="tab-panel-organization"
                :customer="user"
                customer-organizations
              />
            </template>
            <UserRelatedCustomerTickets v-else :customer="user" />
          </CommonSectionContainer>

          <UserTicketBarChart
            v-if="hasPermission('ticket.agent')"
            ref="chart"
            :user-id="userId"
            class="w-fit @xl:col-span-2"
          />
        </section>
      </div>
    </CommonLoader>
  </LayoutContent>
</template>
