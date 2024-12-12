<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useForm } from '#shared/components/Form/useForm.ts'

import { usePersistentStates } from '#desktop/pages/ticket/composables/usePersistentStates.ts'
import {
  type TicketSidebarProps,
  type TicketSidebarEmits,
} from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarWrapper from '../TicketSidebarWrapper.vue'

import TicketSidebarInformationContent from './TicketSidebarInformationContent.vue'

const props = defineProps<TicketSidebarProps>()

const { persistentStates } = usePersistentStates()

// Form reference may be empty until it's initialized, rendering the subsequent call to composable non-reactive.
//   Make sure to wrap it in a computed property in order to keep it reactive.
const form = computed(() => props.context.form)

const { isDirty } = useForm(form)

const emit = defineEmits<TicketSidebarEmits>()

emit('show')
</script>

<template>
  <TicketSidebarWrapper
    :key="sidebar"
    :sidebar="sidebar"
    :sidebar-plugin="sidebarPlugin"
    :selected="selected"
    :update-indicator="isDirty"
  >
    <TicketSidebarInformationContent
      v-model="persistentStates"
      :context="context"
      :sidebar-plugin="sidebarPlugin"
    />
  </TicketSidebarWrapper>
</template>
