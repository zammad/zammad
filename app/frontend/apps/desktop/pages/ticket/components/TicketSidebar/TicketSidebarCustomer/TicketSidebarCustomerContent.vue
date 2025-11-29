<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, type ComputedRef } from 'vue'

import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import { useUserNoteUpdateMutation } from '#shared/entities/user/graphql/mutations/noteUpdate.api.ts'
import { EnumTicketStateTypeCategory, type Organization, type User } from '#shared/graphql/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import NavigationMenuList from '#desktop/components/NavigationMenu/NavigationMenuList.vue'
import { NavigationMenuDensity } from '#desktop/components/NavigationMenu/types.ts'
import TicketListPopoverWithTrigger from '#desktop/components/Ticket/TicketListPopoverWithTrigger.vue'
import UserInfo from '#desktop/components/User/UserInfo.vue'
import type { TicketInformation } from '#desktop/entities/ticket/types.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import {
  type TicketSidebarContentProps,
  TicketSidebarScreenType,
} from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarContent from '../TicketSidebarContent.vue'

interface Props extends TicketSidebarContentProps {
  customer: User
  secondaryOrganizations: ReturnType<typeof normalizeEdges<Partial<Organization>>>
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
    import('#desktop/pages/ticket/components/TicketDetailView/actions/TicketChangeCustomer/TicketChangeCustomerFlyout.vue'),
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
    icon: 'user',
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
    <UserInfo :user="customer" has-organization-popover />

    <ObjectAttributes
      :attributes="objectAttributes"
      :object="customer"
      :skip-attributes="['firstname', 'lastname', 'organization_id', 'organization_ids']"
      :inline-editable="{ note: useUserNoteUpdateMutation }"
    />

    <CommonSimpleEntityList
      v-if="secondaryOrganizations.totalCount"
      id="customer-secondary-organizations"
      v-model="persistentStates.collapseOrganizations"
      :type="EntityType.Organization"
      :label="__('Secondary organizations')"
      :entity="secondaryOrganizations"
      has-popover
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
            id: 'open',
            label: __('open tickets'),
            title: __('Open Tickets'),
            icon: 'check-circle-no',
            iconColor: 'fill-yellow-500',
            count: customer?.ticketsCount?.open || 0,
            route: `/search/${customer?.ticketsCount?.openSearchQuery ?? ''}?entity=Ticket`,
          },
          {
            id: 'closed',
            label: __('closed tickets'),
            title: __('Closed Tickets'),
            icon: 'check-circle-outline',
            iconColor: 'fill-green-400',
            count: customer?.ticketsCount?.closed || 0,
            route: `/search/${customer?.ticketsCount?.closedSearchQuery ?? ''}?entity=Ticket`,
          },
        ]"
      >
        <template #default="{ entry, paddingClasses, countSize, countVariant }">
          <TicketListPopoverWithTrigger
            :filters="{
              customerId: customer.id,
              stateTypeCategory:
                entry.id === 'open'
                  ? EnumTicketStateTypeCategory.Open
                  : EnumTicketStateTypeCategory.Closed,
            }"
            :title="entry.title!"
            :no-results="entry.count === 0"
            :trigger-class="[
              'focus-visible-app-default flex items-center gap-1 rounded-lg! text-sm text-gray-100 hover:bg-blue-600 hover:text-black! hover:no-underline! dark:text-neutral-400 dark:hover:bg-blue-900 dark:hover:text-white!',
              paddingClasses,
            ]"
            :trigger-link="typeof entry.route === 'string' ? entry.route : undefined"
            :popover-config="{
              orientation: 'left',
            }"
            no-hover-styling
          >
            <CommonIcon
              size="small"
              aria-hidden="true"
              class="h-4 shrink-0"
              :class="entry.iconColor"
              :name="entry.icon!"
            />
            <CommonLabel class="line-clamp-1! grow text-current!">
              {{ $t(entry.label) }}
            </CommonLabel>
            <CommonBadge
              class="cursor-pointer leading-snug font-bold"
              :size="countSize"
              :variant="countVariant"
              rounded
            >
              {{ entry.count }}
            </CommonBadge>
          </TicketListPopoverWithTrigger>
        </template>
      </NavigationMenuList>
    </CommonSectionCollapse>
  </TicketSidebarContent>
</template>
