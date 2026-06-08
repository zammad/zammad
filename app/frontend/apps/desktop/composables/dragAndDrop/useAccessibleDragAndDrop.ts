// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { animations } from '@formkit/drag-and-drop'
import { dragAndDrop } from '@formkit/drag-and-drop/vue'
import { type Ref, type ShallowRef } from 'vue'

import { i18n } from '#shared/i18n/index.ts'
import { startAndEndEventsDNDPlugin } from '#shared/utils/startAndEndEventsDNDPlugin.ts'

import type { AnnouncerHandler } from '../accessibility/types'

export const useAccessibleDragAndDrop = <T extends HTMLElement, C extends object | string>(
  parent: ShallowRef<T | null>,
  children: Ref<C[]>,
  announceHandler: AnnouncerHandler,
  options: {
    dndStartCallback?: (parent: HTMLElement) => void
    dndEndCallback?: (parent: HTMLElement) => void
    dropZoneClass?: string
    synthDropZoneClass?: string
    draggingClass?: string
    getValue?: (item: C) => string
  } = {},
) => {
  const {
    dndStartCallback = () => {},
    dndEndCallback = () => {},
    dropZoneClass = '',
    synthDropZoneClass = '',
    draggingClass = '',
    getValue = (item) => (typeof item === 'string' ? item : String(item)),
  } = options

  dragAndDrop({
    // Wrong library bug it should be ShallowRef
    parent: parent as Ref<HTMLElement>,
    values: children,
    plugins: [startAndEndEventsDNDPlugin(dndStartCallback, dndEndCallback), animations()],
    dropZoneClass: `opacity-0 dragging-active ${dropZoneClass}`,
    synthDropZoneClass: `opacity-0 dragging-active ${synthDropZoneClass}`,
    draggingClass: `dragging-active ${draggingClass}`,
    onDragstart: (state) => {
      announceHandler(
        i18n.t(`Drag started for %s.`, getValue(state.draggedNode.data.value as unknown as C)),
      )
    },
    onSort: (event) => {
      announceHandler(
        i18n.t(
          'Sorted %s in user taskbar list to position %s.',
          getValue(event.draggedNodes[0].data.value as unknown as C),
          event.position + 1,
        ),
      )
    },
    onTransfer: (event) => {
      announceHandler(
        i18n.t(
          'Transferred %s from user taskbar list %s at position %s.',
          getValue(event.draggedNodes[0].data.value as unknown as C),
          event.sourceParent.el === (parent as Ref<HTMLElement>).value ? 1 : 2, // Compare source parent element to our list parent to determine list index
          event.targetIndex + 1,
        ),
      )
    },
    onDragend: (state) => {
      announceHandler(
        i18n.t('Drag ended for %s.', getValue(state.draggedNode.data.value as unknown as C)),
      )
    },
  })
}
