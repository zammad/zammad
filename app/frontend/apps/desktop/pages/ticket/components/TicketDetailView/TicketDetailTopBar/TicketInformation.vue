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

const isUpdatingTitle = ref(false)

const { updateTitle } = useTicketEditTitle(computed(() => props.ticket))
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
        v-if="ticket?.customer?.organization"
        class="ltr:-translate-x- -z-10 ltr:-translate-x-1.5 rtl:translate-x-1.5"
        :size="hideDetails ? 'medium' : 'normal'"
        :entity="ticket?.customer.organization"
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
                ticket?.customer?.organization,
            }"
          >
            {{ ticket?.customer.fullname }}
          </CommonLabel>
          <CommonLabel v-if="ticket?.customer.organization?.name">{{
            ticket?.customer.organization?.name
          }}</CommonLabel>
        </div>

        <CommonInlineEdit
          :id="`ticketTitle-${ticket.id}`"
          v-model:editing="isUpdatingTitle"
          size="xl"
          required
          block
          :disabled="!ticket.policy.update"
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
