<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, onMounted, watch } from 'vue'

import TicketSidebarIdoitContent from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarIdoit/TicketSidebarIdoitContent.vue'
import type { ExternalReferencesFormValues } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/types.ts'
import { usePersistentStates } from '#desktop/pages/ticket/composables/usePersistentStates.ts'
import {
  TicketSidebarScreenType,
  type TicketSidebarEmits,
  type TicketSidebarProps,
  TicketSidebarButtonBadgeType,
} from '#desktop/pages/ticket/types/sidebar.ts'
import { useThemeStore } from '#desktop/stores/theme.ts'

import TicketSidebarWrapper from '../../TicketSidebarWrapper.vue'

const props = defineProps<TicketSidebarProps>()

const { persistentStates } = usePersistentStates()

const emit = defineEmits<TicketSidebarEmits>()

const isTicketEditable = computed(
  () => props.context.isTicketEditable?.value ?? true, // True for ticket create screen.
)

const { isDarkMode } = storeToRefs(useThemeStore())

const plugin = computed(() => {
  const icon = isDarkMode.value
    ? `${props.sidebarPlugin.icon}-light`
    : `${props.sidebarPlugin.icon}-dark`

  return {
    ...props.sidebarPlugin,
    icon,
  }
})

const objectIds = computed(() => {
  if (props.context.screenType === TicketSidebarScreenType.TicketCreate)
    return (
      (props.context.formValues as ExternalReferencesFormValues)
        .externalReferences?.idoit || []
    )

  return props.context.ticket?.value?.preferences?.idoit?.object_ids || []
})

const objectBadges = computed(() =>
  objectIds.value?.length
    ? {
        label: __('Objects'),
        type: TicketSidebarButtonBadgeType.Info,
        value: objectIds.value?.length,
      }
    : undefined,
)

const hideSidebar = computed(
  () => !objectIds.value?.length && !isTicketEditable.value,
)

if (props.context.screenType === TicketSidebarScreenType.TicketDetailView) {
  watch(
    hideSidebar,
    (value) => {
      if (value) {
        emit('hide')
      } else {
        emit('show')
      }
    },
    { immediate: true },
  )
} else {
  onMounted(() => {
    emit('show')
  })
}
</script>

<template>
  <TicketSidebarWrapper
    :key="sidebar"
    :sidebar="sidebar"
    :sidebar-plugin="plugin"
    :selected="selected"
    :badge="objectBadges"
  >
    <TicketSidebarIdoitContent
      v-model="persistentStates"
      :screen-type="context.screenType"
      :ticket-id="context.ticket?.value?.id"
      :sidebar-plugin="plugin"
      :object-ids="objectIds"
      :form="context.form"
      :is-ticket-editable="isTicketEditable"
    />
  </TicketSidebarWrapper>
</template>
