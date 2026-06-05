<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'

import CommonInlineEdit from '#desktop/components/CommonInlineEdit/CommonInlineEdit.vue'
import OrganizationPopoverWithTrigger from '#desktop/components/Organization/OrganizationPopoverWithTrigger.vue'
import UserPopoverWithTrigger from '#desktop/components/User/UserPopoverWithTrigger.vue'
import TicketInformationBadgeList from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/TicketInformation/TicketInformationBadgeList.vue'
import { useTicketEditTitle } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/useTicketEditTitle.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

interface Props {
  hideDetails?: boolean
}
const { ticket, ticketId } = useTicketInformation()

defineProps<Props>()

const isUpdatingTitle = ref(false)

const { updateTitle } = useTicketEditTitle(ticketId)
</script>

<template>
  <div
    v-if="ticket"
    class="grid grid-cols-[max-content_1fr] gap-4"
    :class="{ 'items-center gap-3': hideDetails }"
  >
    <div
      class="flex items-center @3xl:items-start"
      :class="{ 'flex-col gap-1.5 @3xl:mt-1 @3xl:flex-row @3xl:gap-0': !hideDetails }"
    >
      <UserPopoverWithTrigger
        v-if="ticket.customer"
        class="z-11 h-min"
        :avatar-config="{
          responsive: true,
          size: hideDetails ? 'medium' : 'normal',
        }"
        :popover-config="{
          placement: 'arrowStart',
        }"
        :user="ticket.customer"
      />
      <OrganizationPopoverWithTrigger
        v-if="ticket.organization"
        class="h-min"
        :class="{
          '@3xl:ltr:-translate-x-1.5 @3xl:rtl:translate-x-1.5': !hideDetails,
          'ltr:-translate-x-1.5 rtl:translate-x-1.5': hideDetails,
        }"
        :avatar-config="{
          responsive: true,
          size: hideDetails ? 'medium' : 'normal',
        }"
        :popover-config="{
          placement: 'arrowStart',
        }"
        :organization="ticket.organization"
      />
    </div>

    <div class="min-w-0 grow basis-full">
      <div
        class="flex flex-col justify-center"
        :class="{
          'mb-3.5': !hideDetails,
        }"
      >
        <div v-if="!hideDetails" class="mb-1 flex items-center gap-1">
          <CommonLabel tag="p" class="line-clamp-1! max-w-1/2 shrink break-all">
            {{ ticket.customer.fullname }}
          </CommonLabel>
          <span v-if="ticket.organization?.name" aria-hidden="true"> &middot; </span>
          <CommonLabel v-if="ticket.organization?.name" class="line-clamp-1! flex-1 grow break-all">
            {{ ticket.organization?.name }}
          </CommonLabel>
        </div>

        <CommonInlineEdit
          v-model:editing="isUpdatingTitle"
          size="xl"
          required
          block
          :class="{ 'min-w-md': !isUpdatingTitle }"
          :disabled="!ticket.policy.update || hideDetails"
          :value="ticket.title"
          :classes="{
            label: hideDetails
              ? 'dark:text-white font-medium line-clamp-1'
              : 'dark:text-white font-medium line-clamp-4',
            input: 'dark:text-white font-medium',
          }"
          :label-attrs="{
            role: 'heading',
            'aria-level': '2',
          }"
          :label="$t('Edit ticket title')"
          @submit-edit="updateTitle"
        />
      </div>

      <TicketInformationBadgeList v-if="!hideDetails" />
    </div>
  </div>
</template>
