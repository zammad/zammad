// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useEventListener, useTimeoutFn, type Fn } from '@vueuse/core'
import { storeToRefs } from 'pinia'
import { computed, ref, toRef, toValue, watch } from 'vue'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { EnumTicketStateColorCode, type TicketBulkPerformInput } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import emitter from '#shared/utils/emitter.ts'

import { useKeepAliveHooks } from '#desktop/composables/useKeepAliveHooks.ts'
import { useTicketBulkUpdate } from '#desktop/entities/ticket/composables/useTicketBulkUpdate.ts'
import {
  BULK_CONFIRMATION_THRESHOLD,
  useTicketBulkUpdateStore,
} from '#desktop/entities/user/current/stores/ticketBulkUpdate.ts'

import { DragAndDropBulkEntityType } from './types.ts'

import type {
  BulkData,
  DragAndDropBulkArgs,
  DragAndDropBulkOptions,
  DragPreviewData,
} from './types.ts'

const LONG_PRESS_DURATION = 200
const MOVE_THRESHOLD_PX = 5
const DROP_SUCCESS_ANIMATION_DURATION = 500

const capturePreviewData = (row: HTMLElement): DragPreviewData => {
  const stateEl = row.querySelector<HTMLElement>('[data-state-color-code]')
  const stateColorCode = (stateEl?.dataset.stateColorCode as EnumTicketStateColorCode) ?? null

  const priorityEl = row.querySelector<HTMLElement>('[data-priority-ui-color]')
  const priorityUiColor = priorityEl ? priorityEl.dataset.priorityUiColor || null : undefined

  // We basically take the first text node of the table cell
  // checkbox - priority icon - ticket state - TEXT(title,etc...)
  const firstTextCell = Array.from(row.querySelectorAll<HTMLElement>('td')).find(
    (td) => !td.querySelector('[role="checkbox"]') && !!td.textContent?.trim(),
  )

  return { stateColorCode, priorityUiColor, columnText: firstTextCell?.textContent?.trim() ?? '' }
}

export const useDragAndDropBulk = (
  { checkedTicketIds, bulkSelector }: DragAndDropBulkArgs,
  options: DragAndDropBulkOptions = { enabled: true },
) => {
  const bulkUpdateStore = useTicketBulkUpdateStore()
  const isBulkTaskRunning = toRef(useTicketBulkUpdateStore(), 'isRunning')
  const { requestBulkConfirmation } = bulkUpdateStore
  const { confirmationPending, isRunning } = storeToRefs(bulkUpdateStore)

  const isActive = ref(false)
  const longPressedItemId = ref<ID | null>(null)
  const pendingItemId = ref<ID | null>(null)
  const pendingRow = ref<HTMLElement | null>(null)
  const dragPreviewData = ref<DragPreviewData | null>(null)
  const cursorPosition = ref<{ x: number; y: number }>({ x: 0, y: 0 })
  const dropSuccessTargetEntity = ref<BulkData | null>(null)

  // Track both conditions: long press elapsed AND pointer moved enough.
  const longPressElapsed = ref(false)
  const hasMovedEnough = ref(false)
  const startPosition = ref<{ x: number; y: number } | null>(null)

  const getItemIdFromEvent = (event: PointerEvent): ID | null => {
    const row = (event.target as HTMLElement).closest<HTMLElement>('[data-item-id]')

    // if ticket policy update is not given the the row is disabled
    // It get's set for each table row, so we don't need to pass all the tickets
    if (!row) return null

    const checkbox = row.querySelector<HTMLElement>('[role="checkbox"]')
    if (checkbox?.getAttribute('aria-disabled') === 'true') return null

    return row.dataset.itemId ?? null
  }

  const { isTouchDevice } = useTouchDevice()

  const activate = () => {
    if (isTouchDevice.value || isBulkTaskRunning.value || isActive.value) return

    const itemId = pendingItemId.value

    longPressedItemId.value = itemId && !checkedTicketIds.value.has(itemId) ? itemId : null

    if (longPressedItemId.value) {
      checkedTicketIds.value.add(longPressedItemId.value)
    }

    if (checkedTicketIds.value.size === 0) return

    if (pendingRow.value) {
      dragPreviewData.value = capturePreviewData(pendingRow.value)
    }

    emitter.emit('close-popover')
    isActive.value = true
  }

  const tryActivate = () => {
    if (!longPressElapsed.value || !hasMovedEnough.value) return

    activate()
  }

  const { start: startLongPress, stop: stopLongPress } = useTimeoutFn(
    () => {
      longPressElapsed.value = true
      tryActivate()
    },
    LONG_PRESS_DURATION,
    { immediate: false },
  )

  const resetState = () => {
    stopLongPress()
    pendingItemId.value = null
    pendingRow.value = null
    longPressElapsed.value = false
    hasMovedEnough.value = false
    startPosition.value = null
  }

  const clearDropSuccessAnimation = () => {
    dropSuccessTargetEntity.value = null
  }

  const closeDragAndDropOverlay = () => {
    longPressedItemId.value = null
    dragPreviewData.value = null
    isActive.value = false
    checkedTicketIds.value.clear()

    resetState()
  }

  const { start: startDropSuccessTimer, stop: stopDropSuccessTimer } = useTimeoutFn(
    (closeDragOverlay = true) => {
      clearDropSuccessAnimation()
      if (closeDragOverlay) closeDragAndDropOverlay()
    },
    DROP_SUCCESS_ANIMATION_DURATION,
    { immediate: false },
  )

  const cancelDragAndDrop = () => {
    stopDropSuccessTimer()
    clearDropSuccessAnimation()

    if (longPressedItemId.value) {
      checkedTicketIds.value.delete(longPressedItemId.value)
    }

    longPressedItemId.value = null
    dragPreviewData.value = null
    isActive.value = false
    resetState()
  }

  const { sendBulkUpdate, notifyBulkSuccess, notifyBulkError } = useTicketBulkUpdate()

  const extractDataFromNode = (node: HTMLElement): BulkData | null => {
    const assignNode = node.closest<HTMLElement>('[data-type][data-internal-id]')

    return assignNode
      ? {
          type: assignNode.dataset.type as DragAndDropBulkEntityType,
          internalId: Number(assignNode.dataset.internalId),
          groupInternalId: assignNode.dataset.groupInternalId
            ? Number(assignNode.dataset.groupInternalId)
            : null,
        }
      : null
  }

  const buildPerformInput = (data: BulkData): TicketBulkPerformInput => {
    if (data.type === DragAndDropBulkEntityType.Macro)
      return { macroId: convertToGraphQLId('Macro', data.internalId) }

    if (data.type === DragAndDropBulkEntityType.Group)
      return { input: { groupId: convertToGraphQLId('Group', data.internalId) } }

    if (data.type === DragAndDropBulkEntityType.Owner) {
      return {
        input: {
          ownerId: convertToGraphQLId('User', data.internalId),
          ...(data.groupInternalId && {
            groupId: convertToGraphQLId('Group', data.groupInternalId),
          }),
        },
      }
    }

    return {}
  }

  const executeBulkUpdate = async (data: BulkData) => {
    if (isRunning.value) return

    const result = await sendBulkUpdate(
      bulkSelector.value,
      buildPerformInput(data),
      checkedTicketIds.value.size,
    )

    if (!result || result.async) return

    const { total, failedCount, invalidTicketIds } = result

    if (failedCount) {
      if (total - failedCount > 0) notifyBulkSuccess(total - failedCount, 5000)

      notifyBulkError(invalidTicketIds.length)
    } else {
      notifyBulkSuccess(total)
    }
  }

  const setSuccessTargetAndClearPreview = (data: BulkData) => {
    dropSuccessTargetEntity.value = data
    dragPreviewData.value = null
  }

  let listeners: Fn[]

  const activateListeners = () => {
    const removePointerDown = useEventListener(document, 'pointerdown', (event: PointerEvent) => {
      if (event.button !== 0) return // Only respond to primary button.

      const itemId = getItemIdFromEvent(event)

      if (!itemId) return

      pendingItemId.value = itemId
      pendingRow.value = (event.target as HTMLElement).closest<HTMLElement>('[data-item-id]')
      startPosition.value = { x: event.clientX, y: event.clientY }
      startLongPress()
    })

    const removePointerMove = useEventListener(document, 'pointermove', (event: PointerEvent) => {
      if (isActive.value) {
        cursorPosition.value = { x: event.clientX, y: event.clientY }
      }

      if (!pendingItemId.value || !startPosition.value) return
      if (hasMovedEnough.value) return // Already passed the threshold.

      const dx = event.clientX - startPosition.value.x
      const dy = event.clientY - startPosition.value.y

      if (dx * dx + dy * dy < MOVE_THRESHOLD_PX * MOVE_THRESHOLD_PX) return

      hasMovedEnough.value = true
      tryActivate()
    })

    const removePointerup = useEventListener(document, 'pointerup', async (event) => {
      // Ignore pointer events while waiting for the user to confirm/cancel.
      if (confirmationPending.value) return
      if (dropSuccessTargetEntity.value) return

      if (!isActive.value) return resetState()

      const data = extractDataFromNode(event.target as HTMLElement)

      if (!data) return cancelDragAndDrop()

      const ticketCount = checkedTicketIds.value.size
      const skipConfirmation = ticketCount <= BULK_CONFIRMATION_THRESHOLD

      if (!skipConfirmation) {
        setSuccessTargetAndClearPreview(data)

        // Show success animation first, then clear it before opening the confirmation dialog.
        await new Promise((resolve) => setTimeout(resolve, DROP_SUCCESS_ANIMATION_DURATION))

        clearDropSuccessAnimation()
      }

      const confirmed = await requestBulkConfirmation(data.type, {
        resolveImmediate: skipConfirmation,
      })

      if (!confirmed) return cancelDragAndDrop()

      executeBulkUpdate(data)

      if (!skipConfirmation) return closeDragAndDropOverlay()

      setSuccessTargetAndClearPreview(data)
      startDropSuccessTimer()
    })

    const removeDragstart = useEventListener(document, 'dragstart', (event: DragEvent) => {
      if (!pendingItemId.value && !isActive.value) return
      if (!(event.target instanceof HTMLElement)) return

      if (event.target.closest('table [data-item-id]')) event.preventDefault()
    })

    // Cancel if pointer leaves the window or the page loses focus.
    const removePointerCancel = useEventListener(document, 'pointercancel', resetState)
    const removePointerLeave = useEventListener(document, 'pointerleave', resetState)
    const removeWindowBlur = useEventListener(window, 'blur', resetState)
    const removeVisibilityChange = useEventListener(document, 'visibilitychange', () => {
      if (document.visibilityState === 'hidden') resetState()
    })

    return [
      removePointerDown,
      removePointerMove,
      removePointerup,
      removeDragstart,
      removePointerCancel,
      removePointerLeave,
      removeWindowBlur,
      removeVisibilityChange,
    ]
  }

  const deactivateListeners = () => {
    if (!listeners) return

    listeners.forEach((remove) => remove())
  }

  const reactivateListeners = () => {
    // Remove first previous filters in case they exist
    // to make sure they are registered always on the correct instance
    if (listeners) deactivateListeners()

    listeners = activateListeners()

    return listeners
  }

  const isEnabled = computed(() => toValue(options.enabled))

  watch(isEnabled, (enabled) => {
    if (enabled) return reactivateListeners()

    deactivateListeners()
    cancelDragAndDrop()
  })

  useKeepAliveHooks({
    onInitialActivated() {
      if (isEnabled.value) reactivateListeners()
    },
    onReactivated() {
      if (isEnabled.value) reactivateListeners()
    },
    onDeactivated() {
      if (!isEnabled.value) return

      deactivateListeners()
      cancelDragAndDrop()
    },
  })

  return {
    isActive,
    cursorPosition,
    dragPreviewData,
    dropSuccessTargetEntity,
    cancelDragAndDrop,
  }
}
