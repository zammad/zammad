<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, watch } from 'vue'

import { useUserDetail } from '#shared/entities/user/composables/useUserDetail.ts'

import TicketSidebarButton from './TicketSidebarButton.vue'

import type {
  TicketSidebarButtonProps,
  TicketSidebarButtonEmits,
} from '../types.ts'

const props = defineProps<TicketSidebarButtonProps>()

const emit = defineEmits<TicketSidebarButtonEmits>()

const customerId = computed(() => Number(props.context.formValues.customer_id))

const { user: customer } = useUserDetail(customerId, undefined, 'cache-first')

watch(customer, (newValue) => {
  if (!newValue?.organization) {
    emit('hide')
  }
  emit('show')
})
</script>

<template>
  <TicketSidebarButton
    :key="sidebar"
    :name="sidebar"
    :label="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
    :selected="selected"
  />
</template>
