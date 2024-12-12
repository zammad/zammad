<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, type ComputedRef } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import type { Organization, UserQuery } from '#shared/graphql/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import NavigationMenuList from '#desktop/components/NavigationMenu/NavigationMenuList.vue'
import { NavigationMenuDensity } from '#desktop/components/NavigationMenu/types.ts'
import type { TicketInformation } from '#desktop/entities/ticket/types.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import {
  type TicketSidebarContentProps,
  TicketSidebarScreenType,
} from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarContent from '../TicketSidebarContent.vue'

interface Props extends TicketSidebarContentProps {
  customer: UserQuery['user']
  secondaryOrganizations: ReturnType<
    typeof normalizeEdges<Partial<Organization>>
  >
  objectAttributes: ObjectAttribute[]
}

const props = defineProps<Props>()

const persistentStates = defineModel<ObjectLike>({ required: true })

defineEmits<{
  'load-more-secondary-organizations': []
}>()

const CUSTOMER_FLYOUT_KEY = 'ticket-change-customer'

const { open: openChangeCustomerFlyout } = useFlyout({
  name: CUSTOMER_FLYOUT_KEY,
  component: () =>
    import(
      '#desktop/pages/ticket/components/TicketDetailView/actions/TicketChangeCustomer/TicketChangeCustomerFlyout.vue'
    ),
})

let ticket: TicketInformation['ticket']
let isTicketAgent: ComputedRef<boolean>
let isTicketEditable: ComputedRef<boolean>

// :TODO find a way to provide the ticket via prop
if (props.context.screenType === TicketSidebarScreenType.TicketDetailView) {
  ;({ ticket } = useTicketInformation())
  ;({ isTicketAgent, isTicketEditable } = useTicketView(ticket))
}

const actions = computed<MenuItem[]>(() => [
  {
    key: CUSTOMER_FLYOUT_KEY,
    label: __('Change customer'),
    icon: 'person',
    show: () => ticket && isTicketAgent.value && isTicketEditable.value,
    onClick: () =>
      openChangeCustomerFlyout({
        ticket,
      }),
  },
])
</script>

<template>
  <TicketSidebarContent
    v-model="persistentStates.scrollPosition"
    :title="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
    :entity="customer"
    :actions="actions"
  >
    <div class="flex gap-2">
      <CommonUserAvatar v-if="customer" :entity="customer" size="normal" />
      <div class="flex flex-col justify-center gap-px">
        <CommonLabel size="large" class="text-gray-300 dark:text-neutral-400">
          {{ customer?.fullname }}
        </CommonLabel>

        <CommonLink
          v-if="customer?.organization"
          :link="`/organizations/${customer.organization?.internalId}`"
          class="text-sm leading-snug"
        >
          {{ customer?.organization.name }}
        </CommonLink>
      </div>
    </div>

    <ObjectAttributes
      :attributes="objectAttributes"
      :object="customer"
      :skip-attributes="['firstname', 'lastname']"
    />

    <CommonSimpleEntityList
      v-if="secondaryOrganizations.totalCount"
      id="customer-secondary-organizations"
      v-model="persistentStates.collapseOrganizations"
      :type="EntityType.Organization"
      :label="__('Secondary organizations')"
      :entity="secondaryOrganizations"
      @load-more="$emit('load-more-secondary-organizations')"
    />

    <CommonSectionCollapse
      id="customer-tickets"
      v-model="persistentStates.collapseTickets"
      :title="__('Tickets')"
    >
      <NavigationMenuList
        class="mt-1"
        :density="NavigationMenuDensity.Dense"
        :items="[
          {
            label: __('open tickets'),
            icon: 'check-circle-no',
            iconColor: 'fill-yellow-500',
            count: customer?.ticketsCount?.open || 0,
            route: '/search/ticket/open',
          },
          {
            label: __('closed tickets'),
            icon: 'check-circle-outline',
            iconColor: 'fill-green-400',
            count: customer?.ticketsCount?.closed || 0,
            route: '/search/ticket/closed',
          },
        ]"
      />
    </CommonSectionCollapse>
  </TicketSidebarContent>
</template>
