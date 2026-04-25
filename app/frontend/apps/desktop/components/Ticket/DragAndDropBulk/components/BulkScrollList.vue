<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useEventListener } from '@vueuse/core'
import { useIntervalFn, whenever, type Pausable } from '@vueuse/shared'
import { computed, onMounted, ref, toRef, useTemplateRef, watch } from 'vue'

import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import { type BulkData, type BulkScrollListItem, DragAndDropBulkEntityType } from '../types.ts'

import BulkEntityCard from './BulkEntityCard.vue'
import BulkScrollButton from './BulkScrollButton.vue'

interface Props {
  list?: BulkScrollListItem[]
  dropSuccessTargetEntity?: BulkData | null
}

const props = defineProps<Props>()

const scrollPosition = defineModel<number>('scroll-position', {
  default: 0,
})

const locale = useLocaleStore()
const localeData = toRef(locale, 'localeData')
const isLtrLocale = computed(() => localeData.value?.dir !== EnumTextDirection.Rtl)
defineEmits<{
  'go-inside-group': [number]
}>()

const scrollContainer = useTemplateRef('scroll-container')

const showScrollButtonStart = ref(false)
const showScrollButtonEnd = ref(false)

const calculateScrollButtonStart = () => {
  if (!scrollContainer.value) return

  showScrollButtonStart.value = Math.abs(scrollContainer.value.scrollLeft) > 0
}

const calculateScrollButtonEnd = () => {
  if (!scrollContainer.value) return

  showScrollButtonEnd.value =
    Math.abs(scrollContainer.value.scrollLeft) + scrollContainer.value.clientWidth <
    scrollContainer.value.scrollWidth
}

const recalculateScrollButtons = () => {
  calculateScrollButtonStart()
  calculateScrollButtonEnd()
}

const storeScrollPosition = () => {
  if (!scrollContainer.value) return

  scrollPosition.value = scrollContainer.value.scrollLeft
  recalculateScrollButtons()
}

const restoreScrollPosition = () => {
  if (!scrollContainer.value) return

  scrollContainer.value.scrollLeft = scrollPosition.value
  recalculateScrollButtons()
}

onMounted(restoreScrollPosition)
watch(scrollPosition, restoreScrollPosition)

// The scroll step is based on the width of the card plus the gap between the cards.
const SCROLL_STEP = 160 + 28

// The counter to keep track of how long the user has been scrolling.
//   The longer the user scrolls, the faster the scrolling gets.
const scrollCounter = ref(1)

let scrollIntervalFn: Pausable

const scrollInterval = ref(500)

const scrollByStep = (scrollAmount: number) => {
  if (!scrollContainer.value) return
  if (!isLtrLocale.value) {
    scrollAmount = -scrollAmount
  }

  scrollContainer.value.scrollBy({ left: scrollAmount, behavior: 'smooth' })

  calculateScrollButtonStart()
  calculateScrollButtonEnd()

  scrollCounter.value += 1

  if (scrollCounter.value < 5) return

  // If the user has been scrolling for a while, speed up the scrolling.
  scrollInterval.value = 50
}

const stopScroll = () => {
  if (!scrollIntervalFn?.isActive.value) return

  scrollIntervalFn.pause()
  scrollCounter.value = 1
  scrollInterval.value = 500
}

const beginScroll = (direction: 'start' | 'end') => {
  if (!scrollContainer.value) return

  stopScroll()

  const scrollAmount = direction === 'start' ? -SCROLL_STEP : SCROLL_STEP

  scrollIntervalFn = useIntervalFn(() => scrollByStep(scrollAmount), scrollInterval, {
    immediateCallback: true,
  })
}

// Stop scrolling when mouse cursor leaves the page.
useEventListener(document, 'mouseleave', stopScroll)

whenever(
  () => !showScrollButtonStart.value || !showScrollButtonEnd.value,
  () => {
    stopScroll()
  },
)

const hasGroup = computed(() =>
  props.list?.some((item) => item.type === DragAndDropBulkEntityType.Group),
)

const isDropSuccessTarget = (item: BulkScrollListItem) => {
  const target = props.dropSuccessTargetEntity
  if (!target) return false

  return (
    item.type === target.type &&
    item.internalId === target.internalId &&
    (item.groupInternalId ?? null) === (target.groupInternalId ?? null)
  )
}
</script>

<template>
  <div class="w-full min-w-0">
    <BulkScrollButton
      v-if="showScrollButtonStart"
      direction="start"
      @scroll-start="beginScroll"
      @scroll-stop="stopScroll"
    />
    <BulkScrollButton
      v-if="showScrollButtonEnd"
      direction="end"
      @scroll-start="beginScroll"
      @scroll-stop="stopScroll"
    />

    <ul
      ref="scroll-container"
      class="scroll-bar-hidden flex snap-x flex-row items-start gap-7 overflow-x-auto px-28.5"
      :class="hasGroup ? 'pt-0' : 'py-2'"
      @scrollend="storeScrollPosition"
    >
      <!-- Data attributes are read by useDragAndDropBulk to extract the entity information needed for the mutation. -->
      <li
        v-for="item in list"
        :key="`${item.type}-${item.internalId}-${item.groupInternalId ?? 'root'}-${item.label}`"
        :data-internal-id="item.internalId"
        :data-group-internal-id="item.groupInternalId"
        :data-type="item.type"
        class="snap-center"
      >
        <BulkEntityCard
          :label="item.label"
          :entity-type="item.type"
          :entity="item.object"
          :entity-internal-id="item.internalId"
          :drop-success-active="isDropSuccessTarget(item)"
          :parent-label="item.parentLabel"
          @go-inside-group="
            item.type === DragAndDropBulkEntityType.Group &&
            $emit('go-inside-group', item.internalId)
          "
        />
      </li>
    </ul>
  </div>
</template>
