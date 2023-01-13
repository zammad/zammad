<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { truthy } from '@shared/utils/helpers'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useDialog, closeDialog } from '@shared/composables/useDialog'
import { useTicketView } from '@shared/entities/ticket/composables/useTicketView'
import CommonSectionMenuLink from '@mobile/components/CommonSectionMenu/CommonSectionMenuLink.vue'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonButtonGroup from '@mobile/components/CommonButtonGroup/CommonButtonGroup.vue'
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import type { TicketById } from '@shared/entities/ticket/types'
import { useTicketsMerge } from '../../composable/useTicketsMerge'
import { useTicketSubscribe } from '../../composable/useTicketSubscribe'

// TODO I think the complete dialog should not be available for none agent user (and maybe also for agents without write permission?)

interface Props {
  name: string
  ticket: TicketById
}

const props = defineProps<Props>()

const route = useRoute()
const router = useRouter()

const ticketReactive = toRef(props, 'ticket')
const { isTicketAgent, isTicketEditable } = useTicketView(ticketReactive)

const { autocompleteRef, gqlQuery, openMergeTicketsDialog } = useTicketsMerge(
  ticketReactive,
  () => closeDialog(props.name),
)

const {
  isSubscribed,
  isSubscriptionLoading,
  canManageSubscription,
  toggleSubscribe,
} = useTicketSubscribe(ticketReactive)

const topButtons = computed(() =>
  [
    {
      label: __('Merge tickets'),
      icon: 'mobile-merge',
      hidden: !isTicketEditable.value || !isTicketAgent.value,
      onAction: openMergeTicketsDialog,
    },
    {
      label: isSubscribed.value ? __('Unsubscribe') : __('Subscribe'),
      icon: isSubscribed.value
        ? 'mobile-notification-unsubscribed'
        : 'mobile-notification-subscribed',
      value: 'subscribe',
      hidden: !canManageSubscription.value,
      selected: isSubscribed.value,
      disabled: isSubscriptionLoading.value,
      onAction: toggleSubscribe,
    },
    {
      label: __('Ticket info'),
      icon: 'mobile-info',
      onAction() {
        const informationRoute = {
          name: 'TicketInformationDetails',
          params: {
            internalId: props.ticket.internalId,
          },
        }
        closeDialog(props.name)
        if (route.name !== informationRoute.name) {
          router.push(informationRoute)
        }
      },
    },
  ].filter(truthy),
)

const changeCustomerDialog = useDialog({
  name: 'ticket-change-customer',
  component: () =>
    import(
      '@mobile/pages/ticket/components/TicketDetailView/TicketAction/TicketActionChangeCustomerDialog.vue'
    ),
})

const showChangeCustomer = () => {
  if (!props.ticket) return

  changeCustomerDialog.open({
    name: changeCustomerDialog.name,
    ticket: ticketReactive,
  })
}
</script>

<template>
  <CommonDialog :name="name" :label="__('Ticket actions')">
    <div class="w-full px-3">
      <CommonButtonGroup class="py-6" mode="full" :options="topButtons" />
      <FormKit
        ref="autocompleteRef"
        type="autocomplete"
        outer-class="hidden"
        :label="__('Find a ticket')"
        :gql-query="gqlQuery"
        :action-label="__('Confirm merge')"
        :additional-query-params="{ sourceTicketId: ticket.id }"
        :label-empty="__('Start typing to find the ticket to merge into.')"
        action-icon="mobile-merge"
      />
      <!-- Postponed
      <CommonSectionMenu>
        <CommonSectionMenuLink
          :label="__('Execute configured macros')"
          icon="mobile-macros"
          icon-bg="bg-green"
        />
      </CommonSectionMenu> -->
      <!-- Postponed
      <CommonSectionMenu>
        <CommonSectionMenuLink
          :label="__('History')"
          icon="mobile-history"
          icon-bg="bg-gray"
        />
      </CommonSectionMenu> -->
      <CommonSectionMenu v-if="isTicketEditable && isTicketAgent">
        <CommonSectionMenuLink
          :label="__('Change customer')"
          @click="showChangeCustomer"
        >
          <template #icon>
            <CommonUserAvatar :entity="ticket.customer" size="small" />
          </template>
        </CommonSectionMenuLink>
      </CommonSectionMenu>
    </div>
  </CommonDialog>
</template>
