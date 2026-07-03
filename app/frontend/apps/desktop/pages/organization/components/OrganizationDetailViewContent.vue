<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useTemplateRef } from 'vue'
import { useRouter } from 'vue-router'

import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useReducedMotion } from '#shared/composables/useReducedMotion.ts'
import { useOrganizationDetail } from '#shared/entities/organization/composables/useOrganizationDetail.ts'
import { useOrganizationEntity } from '#shared/entities/organization/composables/useOrganizationEntity.ts'
import { useOrganizationNoteUpdateMutation } from '#shared/entities/organization/graphql/mutations/noteUpdate.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import { scrollIntoView } from '#shared/utils/dom.ts'
import emitter from '#shared/utils/emitter.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonFloatingToolbar from '#desktop/components/CommonFloatingToolbar/CommonFloatingToolbar.vue'
import CommonIndicator from '#desktop/components/CommonIndicator/CommonIndicator.vue'
import { useIndicator } from '#desktop/components/CommonIndicator/useIndicator.ts'
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
import OrganizationDetailViewContentSkeleton from './OrganizationDetailViewContentSkeleton.vue'
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

const { isIntersecting: isReachingBottom } = useIndicator()
const { isIntersecting: isReachingTop } = useIndicator()

const { hasReducedMotion } = useReducedMotion()

const scrollTo = (position: 'start' | 'end' = 'end') => {
  scrollIntoView(contentContainerElement.value, position, {
    behavior: hasReducedMotion.value ? 'instant' : 'auto',
  })
}
</script>

<template>
  <LayoutContent
    name="organization-detail"
    no-padding
    background-variant="primary"
    content-alignment="center"
    no-scrollable
  >
    <CommonLoader class="size-full" :loading="loadingWithoutCachedResult">
      <template #skeleton>
        <OrganizationDetailViewContentSkeleton />
      </template>

      <div ref="content-container" class="@container size-full overflow-y-auto">
        <CommonIndicator v-model="isReachingTop" />

        <OrganizationDetailTopBar
          :organization="organization"
          :organization-display-name="organizationDisplayName"
          :content-container-element="contentContainerElement"
        />
        <section
          class="mx-auto grid w-full max-w-5xl min-w-xs grid-cols-1 gap-6 px-5.5 py-3 @2xl:grid-cols-2"
        >
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
            :label="__('Organization tickets')"
          >
            <OrganizationRelatedTickets :organization="organization" />
          </CommonSectionContainer>

          <OrganizationTicketBarChart
            v-if="hasPermission('ticket.agent')"
            ref="chart"
            class="@2xl:col-span-2"
            :organization-id="organizationId"
          />
        </section>

        <div class="sticky bottom-3 h-0 print:hidden">
          <CommonFloatingToolbar
            class="absolute inset-e-3 bottom-3 print:hidden"
            :is-reaching-bottom="isReachingBottom"
            :is-reaching-top="isReachingTop"
            @scroll-to-end="scrollTo()"
            @scroll-to-start="scrollTo('start')"
          />
        </div>
        <CommonIndicator v-model="isReachingBottom" />
      </div>
    </CommonLoader>
  </LayoutContent>
</template>
