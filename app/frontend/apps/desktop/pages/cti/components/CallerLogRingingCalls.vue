<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import CommonAvatar from '#shared/components/CommonAvatar/CommonAvatar.vue'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { i18n } from '#shared/i18n.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { callerTicketCreateRoute } from '#desktop/entities/cti/utils/routeLocation.ts'

import { useCallerUserCreate } from '../composables/useCallerUserCreate.ts'
import {
  getCallerLogMatchName,
  getCallerLogNamedMatches,
  getCallerLogStatus,
  getCallerLogStatusDisplay,
} from '../utils/callerLog.ts'

import CallerLogParticipant from './CallerLogParticipant.vue'

import type { RingingCall } from '../types.ts'

interface Props {
  calls: RingingCall[]
  collapsed?: boolean
}

const props = defineProps<Props>()

defineEmits<{
  select: []
}>()

const router = useRouter()

const { openCallerUserCreateFlyout } = useCallerUserCreate()

const application = useApplicationStore()

const nameFormat = computed(() => application.config.user_name_format)

// The same tab a pickup of the call opens for that customer.
const openTicketCreate = (call: RingingCall, userInternalId?: number) =>
  router.push(
    callerTicketCreateRoute(call, userInternalId ? { internalId: userInternalId } : undefined),
  )

// Collapsed, a call is reduced to the avatar of its caller, which then opens the sidebar
//   to work on it; the label names the button.
const rows = computed(() =>
  props.calls.map((call) => {
    const [match] = getCallerLogNamedMatches(call.fromMatches, nameFormat.value)
    const number = call.fromPretty || call.from

    return {
      call,
      caller: match?.user,
      callerLabel: match
        ? i18n.t('Ringing call from %s', getCallerLogMatchName(match, nameFormat.value))
        : i18n.t('Ringing call from unknown caller %s', number),
      status: getCallerLogStatusDisplay(call),
      statusLabel: i18n.t(getCallerLogStatus(call)),
    }
  }),
)
</script>

<template>
  <!-- No scroll box here: it would clip the rings, and the sidebar scrolls as a whole. -->
  <ul v-if="collapsed" class="mt-0.5 flex flex-col gap-0.5" :aria-label="$t('Ringing calls')">
    <li v-for="({ call, caller, callerLabel }, index) in rows" :key="call.id" class="flex">
      <CommonButton
        v-tooltip="callerLabel"
        class="bg-blue-200 p-1.5! text-neutral-400 hover:outline-blue-900 dark:bg-stone-700"
        :class="{
          'rounded-t-none! rounded-b-none!': index === 0 && rows.length > 1,
          'rounded-none!': index > 0 && index < rows.length - 1,
          'rounded-t-none! rounded-b-lg!': index === rows.length - 1,
        }"
        size="large"
        variant="none"
        block
        no-truncate
        :aria-label="callerLabel"
        @click="$emit('select')"
      >
        <CommonUserAvatar v-if="caller" :entity="caller" size="xs" decorative />
        <CommonAvatar v-else class="bg-yellow-300" size="xs" decorative />
      </CommonButton>
    </li>
  </ul>
  <ul
    v-else
    class="mx-1 mt-0.5 flex max-h-[20vh] flex-col divide-y-2 divide-neutral-100 overflow-y-auto rounded-b-lg bg-blue-200 dark:divide-gray-900 dark:bg-stone-700"
    :aria-label="$t('Ringing calls')"
  >
    <li
      v-for="{ call, status, statusLabel } in rows"
      :key="call.id"
      class="flex items-center gap-2 px-1.5 py-1"
    >
      <CallerLogParticipant
        :matches="call.fromMatches"
        :name-format="nameFormat"
        :number="call.from"
        :number-pretty="call.fromPretty"
        :comment="call.fromComment"
        :is-external="call.direction === 'in'"
        is-sidebar
        @ticket-create="(userInternalId) => openTicketCreate(call, userInternalId)"
        @user-create="openCallerUserCreateFlyout"
      />
      <!-- The tooltip writes the accessible name, so the icon must not be decorative. -->
      <CommonIcon
        v-tooltip="statusLabel"
        class="shrink-0"
        :class="status.iconClass"
        :name="status.icon"
        size="tiny"
      />
    </li>
  </ul>
</template>
