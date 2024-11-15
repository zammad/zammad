<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonAvatar from '#shared/components/CommonAvatar/CommonAvatar.vue'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type { HistoryRecordIssuer, User } from '#shared/graphql/types.ts'

import { useHistoryEvents } from './composables/useHistoryEvents.ts'

interface Props {
  issuer: HistoryRecordIssuer
}

const { issuer } = defineProps<Props>()

const { issuedBySystemService, issuedBySystemUser, getIssuerName } =
  useHistoryEvents()
</script>

<template>
  <CommonLabel class="p-2">
    <CommonIcon
      v-if="issuedBySystemService(issuer)"
      class="text-yellow-700 dark:text-yellow-300"
      name="play-circle"
      size="small"
    />
    <!-- TODO: Link to user profile -->
    <CommonUserAvatar
      v-else-if="!issuedBySystemUser(issuer)"
      :entity="issuer as User"
      size="xs"
      no-indicator
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
