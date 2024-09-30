<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

import CommonTicketEscalationIndicator from '#desktop/components/CommonTicketEscalationIndicator/CommonTicketEscalationIndicator.vue'
import CommonTicketPriorityIndicator from '#desktop/components/CommonTicketPriorityIndicator/CommonTicketPriorityIndicator.vue'
import CommonTicketStateIndicator from '#desktop/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import ChecklistBadgeList from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/TicketInformation/TicketInformationBadgeList/ChecklistBadgeList.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

const { ticket } = useTicketInformation()

const { config } = storeToRefs(useApplicationStore())

const isChecklistFeatureEnabled = computed(() => !!config.value.checklist)
</script>

<template>
  <div
    v-if="ticket"
    class="flex max-w-full items-center gap-2.5 text-nowrap *:h-7"
  >
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

    <ChecklistBadgeList v-if="isChecklistFeatureEnabled" />
  </div>
</template>
