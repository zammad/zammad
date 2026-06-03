<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts" generic="T extends Tab | NavigationTab">
import {
  useElementVisibility,
  useResizeObserver,
  type UseElementVisibilityOptions,
} from '@vueuse/core'
import { computed, ref, toRef, useTemplateRef, watch } from 'vue'

import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import getUuid from '#shared/utils/getUuid.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type { Tab, NavigationTab, MarkerStyle } from '#desktop/components/CommonTabs/types.ts'
import { useKeepAliveHooks } from '#desktop/composables/useKeepAliveHooks.ts'

interface Props {
  tabs: T[]
  activeKeys: T['key'][]
  multiple?: boolean
  label?: string
  containerRole?: string
  listItemRole?: string
}

const props = defineProps<Props>()

defineOptions({
  inheritAttrs: false,
})

const labelId = getUuid()

const hasMarker = computed(() => !props.multiple)

const containerElement = useTemplateRef<HTMLElement>('container')
const tabInstances = useTemplateRef<HTMLElement[]>('tabs')

const listStartElement = useTemplateRef('list-start')
const listEndElement = useTemplateRef('list-end')

// `w-11` (44px) + container paddings (2 * 4px) = 52px.
const scrollButtonRootMargin = '0px 52px 0px 52px'

// We need the root margin to accommodate for the size of the scroll buttons, as the
// indicator is hidden behind the buttons
const visibilityOptions: UseElementVisibilityOptions = {
  rootMargin: scrollButtonRootMargin,
  threshold: 1,
  scrollTarget: containerElement,
}

const isAtStart = useElementVisibility(listStartElement, visibilityOptions)
const isAtEnd = useElementVisibility(listEndElement, visibilityOptions)

// If both buttons are visible, the full list fits and there is no horizontal overflow.
const isScrollable = computed(() => !(isAtStart.value && isAtEnd.value))

const locale = useLocaleStore()
const localeData = toRef(locale, 'localeData')
const isLtrLocale = computed(() => localeData.value?.dir !== EnumTextDirection.Rtl)

//  Marker pill
const defaultTabIndex = computed(() => props.tabs.findIndex((tab) => tab.default))

const activeTabIndex = computed<number | null>(() => {
  const activeKey = props.activeKeys[0]
  const index = props.tabs.findIndex((tab) => tab.key === activeKey)

  return index === -1 ? defaultTabIndex.value : index
})

const selectedIndex = computed<number | null>(() => {
  if (!hasMarker.value) return null

  return activeTabIndex.value
})

const markerStyle = ref<MarkerStyle | null>(null)
const transitionsEnabled = ref(false)

const measureMarker = () => {
  const index = selectedIndex.value ?? defaultTabIndex.value

  if (index == null || index < 0) {
    markerStyle.value = null
    return
  }

  const tabElement = tabInstances.value?.at(index)

  if (!tabElement) {
    markerStyle.value = null
    return
  }

  const el = tabElement as HTMLElement
  markerStyle.value = {
    top: `${el.offsetTop}px`,
    left: `${el.offsetLeft}px`,
    width: `${el.offsetWidth}px`,
    height: `${el.offsetHeight}px`,
  }
}

const centerActiveTab = (behavior: ScrollBehavior) => {
  const index = activeTabIndex.value

  if (index == null || index < 0) return

  const tabElement = tabInstances.value?.at(index)

  tabElement?.scrollIntoView?.({
    block: 'nearest',
    inline: 'center',
    behavior,
  })
}

// We don't apply transition before we have the calculation
// to prevent this flash of transition initially
const enableTransitionsAfterPaint = () => {
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      transitionsEnabled.value = true
    })
  })
}

const stopWatcher = watch(selectedIndex, measureMarker, { flush: 'post' })
if (!hasMarker.value) stopWatcher()

watch(activeTabIndex, () => centerActiveTab('smooth'), { flush: 'post' })

watch(
  () => props.tabs,
  () => {
    if (!hasMarker.value) return

    // tabs can be recomputed we need to make sure to redraw the background pill
    transitionsEnabled.value = false

    measureMarker()
    centerActiveTab('auto')

    enableTransitionsAfterPaint()
  },
  { deep: true, flush: 'post' },
)

useResizeObserver(containerElement, measureMarker)

useKeepAliveHooks({
  onInitialActivated() {
    measureMarker()
    centerActiveTab('instant')
    enableTransitionsAfterPaint()
  },
  onReactivated() {
    transitionsEnabled.value = false

    measureMarker()
    centerActiveTab('instant')
    enableTransitionsAfterPaint()
  },
})

// A fixed step is large enough to cross into the next snap
// interval, so snap-x/snap-center settles on the next tab.
const SCROLL_STEP = 160

const beginScroll = (direction: 'start' | 'end') => {
  if (!containerElement.value) return

  let scrollAmount = direction === 'start' ? -SCROLL_STEP : SCROLL_STEP
  if (!isLtrLocale.value) {
    scrollAmount = -scrollAmount
  }

  containerElement.value.scrollBy({ left: scrollAmount, behavior: 'smooth' })
}

const iconNamePerDirection = (isLtr: boolean, direction: 'start' | 'end') => {
  if (isLtr) return direction === 'start' ? 'arrow-left' : 'arrow-right'

  return direction === 'start' ? 'arrow-right' : 'arrow-left'
}

const iconNamePerDirectionStart = computed(() => iconNamePerDirection(isLtrLocale.value, 'start'))
const iconNamePerDirectionEnd = computed(() => iconNamePerDirection(isLtrLocale.value, 'end'))

const everyTabHasIcon = computed(() => props.tabs.every((tab) => tab.icon))
</script>

<template>
  <!-- calc(100%-8px) 8px is p-1 -> 4 * 2 from both sides -->
  <CommonButton
    v-if="isScrollable"
    v-show="!isAtStart"
    ref="start-button"
    v-tooltip="$t('Scroll towards start')"
    variant="none"
    :icon="iconNamePerDirectionStart"
    class="absolute inset-s-1 top-1/2 z-10 h-[calc(100%-8px)]! w-11! -translate-y-1/2 rounded-full! bg-neutral-50/80! text-black -outline-offset-1! backdrop-blur-xs dark:bg-gray-500/80! dark:text-white"
    @click="beginScroll('start')"
  />

  <ul
    ref="container"
    :aria-label="label"
    :role="containerRole"
    :aria-multiselectable="multiple || undefined"
    :aria-labelledby="label ? labelId : undefined"
    class="relative isolate scroll-bar-hidden flex w-full snap-x flex-row items-center overflow-x-auto rounded-full [&>[data-tab]+[data-tab]]:ms-1"
  >
    <li ref="list-start" class="order-first shrink-0" role="presentation" />

    <li
      v-for="tab in tabs"
      :key="tab.key"
      ref="tabs"
      data-tab
      :role="listItemRole"
      class="flex grow @lg:grow-0"
    >
      <slot
        :tab="tab"
        tab-class="rounded-full! px-3.5 py-1 focus-visible-app-default focus-visible:-outline-offset-1"
        :can-display-icon-only="everyTabHasIcon"
      />
    </li>

    <li
      v-if="!multiple"
      role="presentation"
      class="absolute rounded-full bg-white dark:bg-gray-200"
      :class="[
        {
          'transition-all': transitionsEnabled,
          invisible: !markerStyle,
        },
      ]"
      :style="markerStyle"
    />

    <li ref="list-end" class="order-last shrink-0" role="presentation" />
  </ul>

  <CommonButton
    v-if="isScrollable"
    v-show="!isAtEnd"
    ref="end-button"
    v-tooltip="$t('Scroll towards end')"
    variant="none"
    :icon="iconNamePerDirectionEnd"
    class="absolute inset-e-1 top-1/2 z-10 h-[calc(100%-8px)]! w-11! -translate-y-1/2 rounded-full! bg-neutral-50/80! text-black -outline-offset-1! backdrop-blur-xs dark:bg-gray-500/80! dark:text-white"
    @click="beginScroll('end')"
  />
</template>
