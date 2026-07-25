<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onMounted, watch, toRef } from 'vue'

import TicketSidebarSnipeitContent from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarSnipeit/TicketSidebarSnipeitContent.vue'
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

const isDarkMode = toRef(useThemeStore(), 'isDarkMode')

const plugin = computed(() => {
  const icon = isDarkMode.value
    ? `${props.sidebarPlugin.icon}-light`
    : `${props.sidebarPlugin.icon}-dark`

  return {
    ...props.sidebarPlugin,
    icon,
  }
})

const assetIds = computed(() => {
  if (props.context.screenType === TicketSidebarScreenType.TicketCreate)
    return (
      (props.context.formValues as ExternalReferencesFormValues).externalReferences?.snipeit || []
    )

  return props.context.ticket?.value?.preferences?.snipeit?.asset_ids || []
})

const assetBadges = computed(() =>
  assetIds.value?.length
    ? {
        label: __('Assets'),
        type: TicketSidebarButtonBadgeType.Default,
        value: assetIds.value?.length,
      }
    : undefined,
)

const hideSidebar = computed(() => !assetIds.value?.length && !isTicketEditable.value)

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
    :badge="assetBadges"
  >
    <TicketSidebarSnipeitContent
      v-model="persistentStates"
      :screen-type="context.screenType"
      :ticket-id="context.ticket?.value?.id"
      :sidebar-plugin="plugin"
      :asset-ids="assetIds"
      :form="context.form"
      :is-ticket-editable="isTicketEditable"
    />
  </TicketSidebarWrapper>
</template>
