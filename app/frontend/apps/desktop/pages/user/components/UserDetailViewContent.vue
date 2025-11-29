<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, useTemplateRef } from 'vue'

import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useUserDetail } from '#shared/entities/user/composables/useUserDetail.ts'
import { useUserEntity } from '#shared/entities/user/composables/useUserEntity.ts'
import { useUserNoteUpdateMutation } from '#shared/entities/user/graphql/mutations/noteUpdate.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import emitter from '#shared/utils/emitter.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonSectionContainer from '#desktop/components/CommonSectionContainer/CommonSectionContainer.vue'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import CommonTabGroup from '#desktop/components/CommonTabGroup/CommonTabGroup.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import UserTicketBarChart from '#desktop/components/Ticket/TicketBarChart/UserTicketBarChart.vue'
import { usePage } from '#desktop/composables/usePage.ts'
import { useScrollPosition } from '#desktop/composables/useScrollPosition.ts'
import { useCustomerTicketsByFilterUpdatesSubscription } from '#desktop/entities/ticket/graphql/subscriptions/customerTicketsByFilterUpdates.api.ts'

import UserDetailTopBar from './UserDetailTopBar.vue'
import UserRelatedCustomerTickets from './UserRelatedCustomerTickets.vue'

interface Props {
  internalId: string
}

const props = defineProps<Props>()

const userId = computed(() => convertToGraphQLId('User', props.internalId))

const chartInstance = useTemplateRef('chart')

const { user, objectAttributes, secondaryOrganizations, fetchMoreSecondaryOrganizations } =
  useUserDetail(
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

const customerTicketsByFilterSubscription = new SubscriptionHandler(
  useCustomerTicketsByFilterUpdatesSubscription(() => ({
    customerId: userId.value!,
  })),
)

customerTicketsByFilterSubscription.onResult(({ data }) => {
  if (!data?.ticketCustomerTicketsByFilterUpdates.listChanged) return

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
    <CommonLoader class="mt-8" :loading="!user">
      <div ref="content-container" class="h-full w-full overflow-y-auto">
        <UserDetailTopBar
          :user="user"
          :user-display-name="userDisplayName"
          :content-container-element="contentContainerElement"
        />
        <section class="mx-auto w-full max-w-5xl grid grid-cols-2 gap-6 p-6">
          <div class="self-start flex flex-col gap-6">
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

          <CommonSectionContainer class="self-start" :label="__('Related tickets')">
            <CommonTabGroup
              v-model="activeCustomerTicketsTab"
              class="mb-3"
              :tabs="customerTicketsTabs"
            />
            <KeepAlive>
              <UserRelatedCustomerTickets
                v-if="activeCustomerTicketsTab === 'user'"
                id="tab-panel-user"
                :customer="user"
              />
              <UserRelatedCustomerTickets
                v-else-if="activeCustomerTicketsTab === 'organization'"
                id="tab-panel-organization"
                :customer="user"
                customer-organizations
              />
            </KeepAlive>
          </CommonSectionContainer>

          <UserTicketBarChart ref="chart" :user-id="userId" class="col-span-2" />
        </section>
      </div>
    </CommonLoader>
  </LayoutContent>
</template>
