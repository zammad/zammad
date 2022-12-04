<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import CommonButtonGroup from '@mobile/components/CommonButtonGroup/CommonButtonGroup.vue'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuLink from '@mobile/components/CommonSectionMenu/CommonSectionMenuLink.vue'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import CommonOrganizationAvatar from '@shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import { closeDialog } from '@shared/composables/useDialog'
import { useRoute, useRouter } from 'vue-router'
import { computed, toRef } from 'vue'
import { truthy } from '@shared/utils/helpers'
import type { TicketById } from '../../types/tickets'
import { useTicketSubscribe } from '../../composable/useTicketSubscribe'
import { useTicketsMerge } from '../../composable/useTicketsMerge'

interface Props {
  name: string
  ticket: TicketById
}

const props = defineProps<Props>()

const route = useRoute()
const router = useRouter()

const ticketReactive = toRef(props, 'ticket')

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
      permissions: ['ticket.agent'],
      onAction: openMergeTicketsDialog,
    },
    canManageSubscription.value && {
      label: isSubscribed.value ? __('Unsubscribe') : __('Subscribe'),
      icon: isSubscribed.value
        ? 'mobile-notification-unsubscribed'
        : 'mobile-notification-subscribed',
      value: 'subscribe',
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
</script>

<template>
  <CommonDialog :name="name" :label="__('Ticket actions')">
    <template #before-label>
      <!-- TODO what is its purpose? -->
      <button type="button" class="text-white" @click="closeDialog(name)">
        Cancel
      </button>
    </template>
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
      <CommonSectionMenu>
        <CommonSectionMenuLink
          :label="__('Execute configured macros')"
          icon="mobile-macros"
          icon-bg="bg-green"
        />
      </CommonSectionMenu>
      <CommonSectionMenu>
        <CommonSectionMenuLink
          :label="__('History')"
          icon="mobile-history"
          icon-bg="bg-gray"
        />
      </CommonSectionMenu>
      <CommonSectionMenu>
        <CommonSectionMenuLink :label="__('Edit customer')">
          <template #icon>
            <CommonUserAvatar :entity="{ id: '1' }" size="small" />
          </template>
        </CommonSectionMenuLink>
        <CommonSectionMenuLink :label="__('Edit organization')">
          <template #icon>
            <CommonOrganizationAvatar
              :entity="{ name: 'Zammad', active: true }"
              size="small"
            />
          </template>
        </CommonSectionMenuLink>
      </CommonSectionMenu>
    </div>
  </CommonDialog>
</template>
