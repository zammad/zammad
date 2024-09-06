<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { animations, updateConfig } from '@formkit/drag-and-drop'
import { dragAndDrop } from '@formkit/drag-and-drop/vue'
import { storeToRefs } from 'pinia'
import { computed, ref, watch } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useWalker } from '#shared/router/walker.ts'

import CommonSectionMenu from '#mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import { useHeader } from '#mobile/composables/useHeader.ts'
import { useTicketOverviewsStore } from '#mobile/entities/ticket/stores/ticketOverviews.ts'

import TicketOverviewEditItem from '../components/TicketOverviewEditItem.vue'

const overviewStore = useTicketOverviewsStore()

const {
  overviews,
  loading: overviewsLoading,
  overviewsByKey,
} = storeToRefs(overviewStore)

// we store local included, so they won't affect home page
const includedIds = ref(new Set(overviewStore.includedIds.values()))

watch(
  // when overviews are loaded, updated local included
  () => overviewStore.includedIds,
  (ids) => {
    includedIds.value = ids
  },
)

const includedOverviews = computed({
  get: () => {
    return [...includedIds.value]
      .map((id) => overviewsByKey.value[id])
      .filter(Boolean)
  },
  set: (value) => {
    includedIds.value = new Set(value.map((overview) => overview.id))
  },
})

const dndParentRef = ref()

dragAndDrop({
  parent: dndParentRef,
  values: includedOverviews,
  plugins: [animations()],
  dropZoneClass: 'opacity-0',
  touchDropZoneClass: 'opacity-0',
})

const { notify } = useNotifications()

const walker = useWalker()

useHeader({
  title: __('Ticket Overview'),
  backUrl: '/',
  backAvoidHomeButton: true,
  actionTitle: __('Save'),
  onAction() {
    if (!includedOverviews.value.length) {
      notify({
        id: 'no-overview',
        message: __('Please select at least one ticket overview'),
        type: NotificationTypes.Error,
      })
      return
    }

    overviewStore.saveOverviews(includedOverviews.value)
    notify({
      id: 'overview-save',
      message: __('Ticket Overview settings are saved.'),
      type: NotificationTypes.Success,
    })
    walker.back('/')
  },
})

const excludedOverviews = computed(() => {
  return overviews.value.filter(
    (overview) => !includedIds.value.has(overview.id),
  )
})

const removeFromFavorites = (id: string) => {
  includedIds.value.delete(id)
}

const addToFavorites = (id: string) => {
  includedIds.value.add(id)
}

const updateDndDisabledConfig = (disabled: boolean) => {
  updateConfig(dndParentRef.value, { disabled })
}
</script>

<template>
  <div class="mx-4 mt-6">
    <div v-if="overviewsLoading" class="flex items-center justify-center">
      <CommonIcon name="loading" animation="spin" />
    </div>

    <CommonSectionMenu
      v-if="!overviewsLoading"
      :header-label="__('Included ticket overviews')"
      data-test-id="includedOverviews"
    >
      <div ref="dndParentRef">
        <TicketOverviewEditItem
          v-for="overview in includedOverviews"
          :key="overview.id"
          action="delete"
          :overview="overview"
          draggable
          @action="removeFromFavorites(overview.id)"
          @action-active="updateDndDisabledConfig"
        />
      </div>
      <div
        v-if="!includedOverviews.length"
        class="ms-3 flex min-h-[54px] items-center"
      >
        <p>{{ $t('No entries') }}</p>
      </div>
    </CommonSectionMenu>

    <CommonSectionMenu
      v-if="!overviewsLoading"
      :header-label="__('More ticket overviews')"
      data-test-id="excludedOverviews"
    >
      <TicketOverviewEditItem
        v-for="overview of excludedOverviews"
        :key="overview.id"
        action="add"
        :overview="overview"
        @action="addToFavorites(overview.id)"
      />
      <div
        v-if="!excludedOverviews.length"
        class="ms-3 flex min-h-[54px] items-center"
      >
        <p>{{ $t('No entries') }}</p>
      </div>
    </CommonSectionMenu>
  </div>
</template>
