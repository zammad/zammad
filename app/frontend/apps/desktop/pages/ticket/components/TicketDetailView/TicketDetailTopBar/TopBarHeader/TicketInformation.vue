<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'

import CommonOrganizationAvatar from '#shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'

import CommonInlineEdit from '#desktop/components/CommonInlineEdit/CommonInlineEdit.vue'
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
    class="-:gap-4 grid grid-cols-[max-content_1fr]"
    :class="{ 'items-center gap-3': hideDetails }"
  >
    <div class="flex" :class="{ 'mt-1': !hideDetails }">
      <CommonUserAvatar
        v-if="ticket.customer"
        :size="hideDetails ? 'medium' : 'normal'"
        :entity="ticket.customer"
      />
      <CommonOrganizationAvatar
        v-if="ticket.organization"
        class="ltr:-translate-x- -z-10 ltr:-translate-x-1.5 rtl:translate-x-1.5"
        :size="hideDetails ? 'medium' : 'normal'"
        :entity="ticket.organization"
      />
    </div>

    <div class="grow basis-full">
      <div
        class="flex flex-col justify-center"
        :class="{
          'mb-3.5': !hideDetails,
        }"
      >
        <div v-if="!hideDetails" class="mb-1 flex items-center gap-1">
          <CommonLabel
            tag="p"
            class="flex items-center gap-1"
            :class="{
              'after:inline-block after:h-[.12rem] after:w-[.12rem] after:shrink-0 after:rounded-full after:bg-current':
                ticket.organization,
            }"
          >
            {{ ticket.customer.fullname }}
          </CommonLabel>
          <CommonLabel v-if="ticket.organization?.name">
            {{ ticket.organization?.name }}
          </CommonLabel>
        </div>

        <CommonInlineEdit
          v-model:editing="isUpdatingTitle"
          size="xl"
          required
          block
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
