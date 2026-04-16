<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useTemplateRef } from 'vue'
import { useRouter } from 'vue-router'

import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useOrganizationDetail } from '#shared/entities/organization/composables/useOrganizationDetail.ts'
import { useOrganizationEntity } from '#shared/entities/organization/composables/useOrganizationEntity.ts'
import { useOrganizationNoteUpdateMutation } from '#shared/entities/organization/graphql/mutations/noteUpdate.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import emitter from '#shared/utils/emitter.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonSectionContainer from '#desktop/components/CommonSectionContainer/CommonSectionContainer.vue'
import CommonShowMoreButton from '#desktop/components/CommonShowMoreButton/CommonShowMoreButton.vue'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import OrganizationTicketBarChart from '#desktop/components/Ticket/TicketBarChart/OrganizationTicketBarChart.vue'
import { usePage } from '#desktop/composables/usePage.ts'
import { useScrollPosition } from '#desktop/composables/useScrollPosition.ts'
import { useTicketByOrganizationUpdatesSubscription } from '#desktop/entities/ticket/graphql/subscriptions/ticketByOrganizationUpdates.api.ts'

import OrganizationDetailTopBar from './OrganizationDetailTopBar.vue'
import OrganizationRelatedTickets from './OrganizationRelatedTickets.vue'

interface Props {
  internalId: string
}

const router = useRouter()

const props = defineProps<Props>()

const organizationId = computed(() => convertToGraphQLId('Organization', props.internalId))

const {
  organization,
  loadingWithoutCachedResult,
  objectAttributes,
  organizationMembers,
  fetchMoreMembers,
} = useOrganizationDetail(
  organizationId,
  4,
  100,
  // NB: Silence toast notifications for particular errors, these will be handled by the layout taskbar tab component.
  (errorHandler) =>
    errorHandler.type !== GraphQLErrorTypes.Forbidden &&
    errorHandler.type !== GraphQLErrorTypes.RecordNotFound,
  'cache-first',
)

const { organizationDisplayName } = useOrganizationEntity(organization)

usePage({
  metaTitle: organizationDisplayName,
})

const contentContainerElement = useTemplateRef('content-container')

useScrollPosition(contentContainerElement)

const onSearchAll = () => {
  if (!organization.value?.internalId) return

  const { internalId } = organization.value

  router.push(`/search/organization.id:${internalId} OR organizations.id:${internalId}?entity=User`)
}

const { hasPermission } = useSessionStore()

const chartInstance = useTemplateRef('chart')

const organizationTicketsSubscription = new SubscriptionHandler(
  useTicketByOrganizationUpdatesSubscription(
    () => ({
      organizationId: organizationId.value,
    }),
    {
      enabled: hasPermission('ticket.agent'),
    },
  ),
)

organizationTicketsSubscription.onResult(({ data }) => {
  if (!data?.ticketByOrganizationUpdates.listChanged) return

  chartInstance.value?.refetchData()

  emitter.emit(`organization-ticket-list-refetch:${organizationId.value}`)
})
</script>

<template>
  <LayoutContent
    name="organization-detail"
    no-padding
    background-variant="primary"
    content-alignment="center"
    no-scrollable
  >
    <CommonLoader class="mt-8" :loading="loadingWithoutCachedResult">
      <div ref="content-container" class="h-full w-full overflow-y-auto">
        <OrganizationDetailTopBar
          :organization="organization"
          :organization-display-name="organizationDisplayName"
          :content-container-element="contentContainerElement"
        />
        <section class="mx-auto grid w-full max-w-5xl grid-cols-2 gap-6 p-6">
          <div class="flex flex-col gap-6 self-start">
            <CommonSectionContainer
              v-if="organizationMembers?.totalCount > 0"
              :label="__('Members')"
              no-heading
              alternative-background
            >
              <CommonSimpleEntityList
                id="user-secondary-organizations"
                :type="EntityType.User"
                :label="__('Members')"
                :entity="organizationMembers"
                label-size="medium"
                label-class="text-black! dark:text-white! mb-2.5"
                label-tag="h2"
                list-class="grid grid-cols-2 gap-3"
                has-popover
                no-collapse
              >
                <template #trailing="{ entities, totalCount }">
                  <div class="flex justify-end gap-1.5">
                    <CommonShowMoreButton
                      class="self-end"
                      :entities="entities"
                      :total-count="totalCount"
                      @click="fetchMoreMembers"
                    />
                    <CommonButton
                      v-if="totalCount > 4"
                      variant="secondary"
                      size="small"
                      @click="onSearchAll"
                    >
                      {{ $t('Search all') }}
                    </CommonButton>
                  </div>
                </template>
              </CommonSimpleEntityList>
            </CommonSectionContainer>
            <ObjectAttributes
              :attributes="objectAttributes"
              :object="organization"
              :skip-attributes="['name']"
              :inline-editable="{ note: useOrganizationNoteUpdateMutation }"
            />
          </div>

          <CommonSectionContainer
            v-if="
              hasPermission('ticket.agent') &&
              (organization.ticketsCount?.open || organization.ticketsCount?.closed)
            "
            class="self-start"
            :label="__('Organization tickets')"
          >
            <OrganizationRelatedTickets :organization="organization" />
          </CommonSectionContainer>

          <OrganizationTicketBarChart
            v-if="hasPermission('ticket.agent')"
            ref="chart"
            class="col-span-2"
            :organization-id="organizationId"
          />
        </section>
      </div>
    </CommonLoader>
  </LayoutContent>
</template>
