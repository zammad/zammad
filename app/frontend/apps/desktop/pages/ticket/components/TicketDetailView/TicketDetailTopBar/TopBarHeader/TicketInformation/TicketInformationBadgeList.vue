<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonTicketEscalationIndicator from '#desktop/components/CommonTicketEscalationIndicator/CommonTicketEscalationIndicator.vue'
import CommonTicketPriorityIndicator from '#desktop/components/CommonTicketPriorityIndicator/CommonTicketPriorityIndicator.vue'
import CommonTicketStateIndicator from '#desktop/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import ChecklistBadgeList from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/TicketInformation/TicketInformationBadgeList/ChecklistBadgeList.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

const { ticket } = useTicketInformation()

const config = toRef(useApplicationStore(), 'config')

const { isTicketAgent } = useTicketView(ticket)

const isChecklistFeatureEnabled = computed(() => !!config.value.checklist)
</script>

<template>
  <div v-if="ticket" class="flex max-w-full flex-wrap items-center gap-2.5 text-nowrap *:h-7">
    <CommonTicketEscalationIndicator v-if="isTicketAgent" :ticket="ticket" has-popover />

    <CommonTicketStateIndicator :color-code="ticket.stateColorCode" :label="ticket.state.name" />

    <CommonTicketPriorityIndicator v-if="isTicketAgent" :priority="ticket.priority" />

    <CommonBadge variant="tertiary" class="uppercase">
      <CommonDateTime :date-time="ticket.createdAt" absolute-format="date" class="ms-1">
        <template #prefix>
          {{ $t('Created') }}
        </template>
      </CommonDateTime>
    </CommonBadge>

    <ChecklistBadgeList v-if="isTicketAgent && isChecklistFeatureEnabled" />
  </div>
</template>
