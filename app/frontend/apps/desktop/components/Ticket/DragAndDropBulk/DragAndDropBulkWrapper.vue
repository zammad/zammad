<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useElementHover } from '@vueuse/core'
import { computed, ref, toRef, useTemplateRef, watch } from 'vue'

import { useMacros } from '#shared/entities/macro/composables/useMacros.ts'

import CommonOverlayContainer from '#desktop/components/CommonOverlayContainer/CommonOverlayContainer.vue'
import { useTicketBulkEdit } from '#desktop/components/Ticket/TicketBulkEditFlyout/useTicketBulkEdit.ts'
import { useTicketBulkUpdateStore } from '#desktop/entities/user/current/stores/ticketBulkUpdate.ts'

import DragAndDropBulkBottomDrawer from './DragAndDropBulkBottomDrawer.vue'
import DragAndDropBulkConfirmation from './DragAndDropBulkConfirmation.vue'
import DragAndDropBulkCursorPreview from './DragAndDropBulkCursorPreview.vue'
import DragAndDropBulkTopDrawer from './DragAndDropBulkTopDrawer.vue'

import type { DragPreviewData } from './types'

export interface Props {
  cursorPosition: {
    x: number
    y: number
  }
  previewData?: DragPreviewData | null
  dropSuccessTargetId?: number | null
}

const props = defineProps<Props>()

const { macrosSelector } = useTicketBulkEdit()

const { macrosLoaded, macros } = useMacros(macrosSelector)

const bulkTopDrawerElement = useTemplateRef<HTMLElement>('bulk-top-drawer')
const bulkBottomDrawerElement = useTemplateRef<HTMLElement>('bulk-bottom-drawer')

const isTopBarHoveredRaw = useElementHover(bulkTopDrawerElement, {})
const isBottomBarHoveredRaw = useElementHover(bulkBottomDrawerElement, {})
const lockedTopBarHovered = ref(false)
const lockedBottomBarHovered = ref(false)

// We can't disable states we need to safe them to make sure the UI keeps iced during the drop success
watch(
  () => props.dropSuccessTargetId,
  (targetId, previousTargetId) => {
    if (targetId && !previousTargetId) {
      lockedTopBarHovered.value = isTopBarHoveredRaw.value
      lockedBottomBarHovered.value = isBottomBarHoveredRaw.value
      return
    }

    if (!targetId) {
      lockedTopBarHovered.value = isTopBarHoveredRaw.value
      lockedBottomBarHovered.value = isBottomBarHoveredRaw.value
    }
  },
)

const isTopBarHovered = computed(() =>
  props.dropSuccessTargetId ? lockedTopBarHovered.value : isTopBarHoveredRaw.value,
)

const isBottomBarHovered = computed(() =>
  props.dropSuccessTargetId ? lockedBottomBarHovered.value : isBottomBarHoveredRaw.value,
)

const showCancel = computed(() => isTopBarHovered.value || isBottomBarHovered.value)

const confirmationPending = toRef(useTicketBulkUpdateStore(), 'confirmationPending')
</script>

<template>
  <CommonOverlayContainer
    class="fixed inset-0 top-0 isolate z-51 size-full"
    :class="{ 'cursor-grabbing': !confirmationPending && previewData }"
    fullscreen
    :role="undefined"
  >
    <template v-if="confirmationPending">
      <DragAndDropBulkConfirmation
        class="absolute inset-1/2 top-1/2 z-52 -translate-y-1/2 ltr:-translate-x-1/2 rtl:translate-x-1/2"
      />
    </template>

    <template v-else>
      <DragAndDropBulkCursorPreview
        v-if="previewData"
        :cursor-position="cursorPosition"
        :preview-data="previewData"
      />

      <DragAndDropBulkTopDrawer
        v-show="!isBottomBarHovered"
        ref="bulk-top-drawer"
        :is-active="isTopBarHovered"
        :macros-loaded="macrosLoaded"
        :macros="macros"
        :drop-success-target-id="dropSuccessTargetId"
        class="absolute transition-transform duration-200 ease-out"
        :class="{
          '-translate-y-full delay-300': dropSuccessTargetId,
        }"
      />

      <transition name="fade-quick">
        <section
          v-if="showCancel && !dropSuccessTargetId"
          class="absolute inset-1/2 flex w-full -translate-y-1/2 items-center gap-10 px-10 text-white! before:grow before:border before:border-dashed after:grow after:border after:border-dashed ltr:-translate-x-1/2 rtl:translate-x-1/2"
          :class="{
            'top-[calc(50%+7.5rem)]': isTopBarHovered, // 13 rem is the total height of both drawers -> 7.5 is the half
            'top-[calc(50%-7.5rem)]': isBottomBarHovered,
          }"
        >
          <div class="flex flex-col items-center gap-10">
            <CommonIcon name="arrow-down-short" />
            <CommonLabel class="font-bold text-current!" size="xl">{{
              $t('Drag here to cancel')
            }}</CommonLabel>
            <CommonIcon name="arrow-up-short" />
          </div>
        </section>
      </transition>

      <transition name="fade-up">
        <DragAndDropBulkBottomDrawer
          v-show="!isTopBarHovered"
          ref="bulk-bottom-drawer"
          :is-active="isBottomBarHovered"
          :drop-success-target-id="dropSuccessTargetId"
          class="absolute bottom-0 transition-transform duration-200 ease-out"
          :class="{
            'translate-y-full delay-300': dropSuccessTargetId,
          }"
        />
      </transition>
    </template>
  </CommonOverlayContainer>
</template>
