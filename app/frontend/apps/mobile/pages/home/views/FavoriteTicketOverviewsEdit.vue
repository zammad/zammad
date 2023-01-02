<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import Draggable from 'vuedraggable'
import { useHeader } from '@mobile/composables/useHeader'
import {
  NotificationTypes,
  useNotifications,
} from '@shared/components/CommonNotifications'
import { computed, ref, watch } from 'vue'
import { storeToRefs } from 'pinia'
import { useTicketOverviewsStore } from '@mobile/entities/ticket/stores/ticketOverviews'
import { useWalker } from '@shared/router/walker'
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

const { notify } = useNotifications()

const walker = useWalker()

useHeader({
  title: __('Ticket Overview'),
  backTitle: __('Home'),
  backUrl: '/',
  actionTitle: __('Done'),
  onAction() {
    if (!includedOverviews.value.length) {
      notify({
        message: __('Please select at least one ticket overview'),
        type: NotificationTypes.Error,
      })
      return
    }

    overviewStore.saveOverviews(includedOverviews.value)
    notify({
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
</script>

<template>
  <div class="mx-4 mt-6">
    <div v-if="overviewsLoading" class="flex items-center justify-center">
      <CommonIcon name="mobile-loading" animation="spin" />
    </div>

    <CommonSectionMenu
      v-if="!overviewsLoading"
      :header-label="__('Included ticket overviews')"
      data-test-id="includedOverviews"
    >
      <Draggable
        v-model="includedOverviews"
        :animation="100"
        handle=".handler"
        item-key="id"
      >
        <template #item="{ element }">
          <TicketOverviewEditItem
            action="delete"
            :overview="element"
            draggable
            @action="removeFromFavorites(element.id)"
          />
        </template>
      </Draggable>
      <div
        v-if="!includedOverviews.length"
        class="flex min-h-[54px] items-center"
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
        class="flex min-h-[54px] items-center"
      >
        <p>{{ $t('No entries') }}</p>
      </div>
    </CommonSectionMenu>
  </div>
</template>
