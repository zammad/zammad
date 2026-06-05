<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<script lang="ts" setup>
import { useActiveElement, useEventListener } from '@vueuse/core'
import { computed, ref, useTemplateRef } from 'vue'

import { EnumTextDirection } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import getUuid from '#shared/utils/getUuid.ts'

import { useResizeLine } from '#desktop/components/ResizeLine/useResizeLine.ts'
import { useAnnouncer } from '#desktop/composables/accessibility/useAnnouncer.ts'

import { MINIMUM_COLUMN_WIDTH } from './types.ts'

const emit = defineEmits<{
  resize: []
  reset: []
}>()

const resizeLine = useTemplateRef('resize-line')

const resizing = ref(false)

const currentHeader = computed(() => resizeLine.value?.parentElement)

const nextHeader = computed(
  () => currentHeader.value?.nextElementSibling as HTMLElement | null | undefined,
)

const currentHeaderWidth = ref(0)
const nextHeaderWidth = ref(0)

const setCurrentHeaderWidths = () => {
  if (!currentHeader.value || !nextHeader.value) return

  currentHeaderWidth.value = currentHeader.value.clientWidth
  nextHeaderWidth.value = nextHeader.value.clientWidth
}

const setHeaderWidths = (diff: number) => {
  if (!currentHeader.value || !nextHeader.value) return

  if (currentHeaderWidth.value + diff < MINIMUM_COLUMN_WIDTH)
    diff = -(currentHeaderWidth.value - MINIMUM_COLUMN_WIDTH)

  if (nextHeaderWidth.value - diff < MINIMUM_COLUMN_WIDTH)
    diff = nextHeaderWidth.value - MINIMUM_COLUMN_WIDTH

  currentHeader.value.style.width = `${currentHeaderWidth.value + diff}px`
  nextHeader.value.style.width = `${nextHeaderWidth.value - diff}px`
}

const activeElement = useActiveElement()

const { announce, messageNodeId } = useAnnouncer()

const handleKeyStroke = (e: KeyboardEvent, diff: number) => {
  if (activeElement.value !== resizeLine.value) return

  e.preventDefault()

  setCurrentHeaderWidths()
  setHeaderWidths(diff)
  emit('resize')

  // Announce the resulting width via the live region, so screen reader users
  //   get feedback while adjusting the column with the arrow keys.
  if (currentHeader.value)
    announce(i18n.t('Column width: %s pixels', currentHeader.value.clientWidth))
}

const resizeStartX = ref(0)

const { startResizing } = useResizeLine(
  (positionX) => {
    if (!currentHeader.value || !nextHeader.value) return

    let diff = positionX - resizeStartX.value

    if (useLocaleStore().localeData?.dir === EnumTextDirection.Rtl)
      diff = resizeStartX.value - positionX

    setHeaderWidths(diff)
  },
  resizeLine,
  handleKeyStroke,
  {
    orientation: 'vertical',
  },
)

const addRemoveResizingListener = (event: 'mouseup' | 'touchend') => {
  useEventListener(
    event,
    () => {
      resizing.value = false
      emit('resize')
    },
    { once: true },
  )
}

const handleMousedown = (event: MouseEvent) => {
  resizing.value = true
  resizeStartX.value = event.pageX

  addRemoveResizingListener('mouseup')
  setCurrentHeaderWidths()
  startResizing(event)
}

const handleTouchstart = (event: TouchEvent) => {
  resizing.value = true

  if (event.targetTouches[0]) resizeStartX.value = event.targetTouches[0].pageX
  else resizeStartX.value = event.changedTouches[event.changedTouches.length - 1].pageX

  addRemoveResizingListener('touchend')
  setCurrentHeaderWidths()
  startResizing(event)
}

const handleDoubleClick = () => {
  emit('reset')
  resizeLine.value?.blur()
}

const id = getUuid()
</script>
<template>
  <button
    ref="resize-line"
    v-tooltip="$t('Resize column')"
    :aria-describedby="`${id} ${messageNodeId}`"
    tabindex="0"
    class="absolute inset-e-0 top-1/2 h-5 w-1 -translate-y-2.5 cursor-col-resize! rounded-xs bg-neutral-100 hover:bg-blue-600 focus:outline-none focus-visible:bg-blue-800! dark:bg-gray-200 dark:hover:bg-blue-900"
    :class="{
      'bg-blue-800': resizing,
    }"
    @mousedown="handleMousedown"
    @blur="resizing = false"
    @touchstart="handleTouchstart"
    @dblclick="handleDoubleClick"
  >
    <span :id="id" class="sr-only">
      {{ $t('Use the left and right arrow keys to resize the column.') }}
    </span>
  </button>
</template>
