<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonAvatar from '#shared/components/CommonAvatar/CommonAvatar.vue'
import type { HistoryRecordIssuer, User } from '#shared/graphql/types.ts'

import UserPopoverWithTrigger from '#desktop/components/User/UserPopoverWithTrigger.vue'

import { useHistoryEvents } from './useHistoryEvents.ts'

interface Props {
  issuer: HistoryRecordIssuer
}

const { issuer } = defineProps<Props>()

const { issuedBySystemService, issuedBySystemUser, getIssuerName } = useHistoryEvents()
</script>

<template>
  <CommonLabel class="p-2">
    <CommonIcon
      v-if="issuedBySystemService(issuer)"
      class="text-yellow-700 dark:text-yellow-300"
      name="play-circle"
      size="small"
    />

    <UserPopoverWithTrigger
      v-else-if="!issuedBySystemService(issuer) && !issuedBySystemUser(issuer)"
      :avatar-config="{ noIndicator: true, size: 'xs' }"
      :popover-config="{ orientation: 'left' }"
      :user="issuer as User"
    />
    <CommonAvatar
      v-else-if="issuedBySystemUser(issuer)"
      icon="logo"
      class="dark:bg-white"
      size="xs"
    />

    {{ getIssuerName(issuer) }}
  </CommonLabel>
</template>
