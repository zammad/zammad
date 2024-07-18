<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import CommonOrganizationAvatar from '#shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type { TicketById } from '#shared/entities/ticket/types.ts'

import CommonInlineEdit from '#desktop/components/CommonInlineEdit/CommonInlineEdit.vue'
import CommonTicketEscalationIndicator from '#desktop/components/CommonTicketEscalationIndicator/CommonTicketEscalationIndicator.vue'
import CommonTicketPriorityIndicator from '#desktop/components/CommonTicketPriorityIndicator/CommonTicketPriorityIndicator.vue'
import CommonTicketStateIndicator from '#desktop/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import { useTicketEditTitle } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/useTicketEditTitle.ts'

interface Props {
  ticket: TicketById
  hideDetails?: boolean
}

const props = defineProps<Props>()

const ticket = computed(() => props.ticket)

const isUpdatingTitle = ref(false)

const { updateTitle } = useTicketEditTitle(ticket)
</script>

<template>
  <div
    class="-:gap-4 grid grid-cols-[max-content_1fr]"
    :class="{ 'items-center gap-3': hideDetails }"
  >
    <div class="flex" :class="{ 'mt-1': !hideDetails }">
      <CommonUserAvatar
        v-if="ticket?.customer"
        :size="hideDetails ? 'medium' : 'normal'"
        :entity="ticket?.customer"
      />
      <CommonOrganizationAvatar
        v-if="ticket?.customer.organization"
        class="ltr:-translate-x- -z-10 ltr:-translate-x-1.5 rtl:translate-x-1.5"
        :size="hideDetails ? 'medium' : 'normal'"
        :entity="ticket?.customer.organization"
      />
    </div>

    <div class="grow basis-full">
      <div
        class="flex h-10 flex-col justify-center transition-transform duration-300"
        :class="{
          '-translate-y-1': isUpdatingTitle && !hideDetails,
          'mb-3.5': !hideDetails,
        }"
      >
        <div v-if="!hideDetails" class="flex items-center gap-1">
          <CommonLabel
            tag="p"
            class="flex items-center gap-1"
            :class="{ dot: ticket.customer.organization }"
          >
            <span>{{ ticket?.customer.fullname }}</span>
          </CommonLabel>
          <CommonLabel v-if="ticket?.customer.organization?.name">{{
            ticket?.customer.organization?.name
          }}</CommonLabel>
        </div>

        <CommonInlineEdit
          v-model:editing="isUpdatingTitle"
          :value="ticket.title"
          :parent="$refs.parentContainer as HTMLElement"
          required
          :label="$t('ticket title')"
          :cancel-label="$t('Cancel Update')"
          :submit-label="$t('Ticket Update')"
          name="ticketTitle"
          @submit-edit="updateTitle"
        >
          <h2
            ref="ticketHeadingTitle"
            class="line-clamp-1 h-full text-xl font-medium leading-snug text-black dark:text-white"
          >
            {{ ticket.title }}
          </h2>
        </CommonInlineEdit>
      </div>

      <div v-if="!hideDetails" class="flex h-7 gap-2.5">
        <CommonTicketEscalationIndicator :escalation-at="ticket.escalationAt" />
        <CommonTicketStateIndicator
          :color-code="ticket.stateColorCode"
          :label="ticket.state.name"
        />
        <CommonTicketPriorityIndicator :priority="ticket.priority" />
        <CommonBadge variant="tertiary" class="uppercase">
          <CommonDateTime
            :date-time="ticket.createdAt"
            absolute-format="date"
            class="ms-1"
          >
            <template #prefix>
              {{ $t('Created') }}
            </template>
          </CommonDateTime>
        </CommonBadge>
      </div>
    </div>
  </div>
</template>

<style scoped>
.dot::after {
  @apply inline-block h-[.12rem] w-[.12rem] shrink-0 rounded-full bg-current;

  content: '';
}
</style>
