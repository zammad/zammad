<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

const { hasPermission } = useSessionStore()

const isAdmin = computed(() => hasPermission('admin.checklist'))
</script>

<template>
  <CommonLabel tag="p">
    {{ $t('No checklist templates have been created yet.') }}
  </CommonLabel>
  <CommonLabel tag="p">
    {{ $t('With checklist templates you can pre-fill your checklists.') }}
  </CommonLabel>
  <CommonLink v-if="isAdmin" link="/#manage/checklists" size="medium">
    {{ $t('Create a new checklist template in the admin interface.') }}
  </CommonLink>
</template>
