// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { animations } from '@formkit/drag-and-drop'
import { dragAndDrop } from '@formkit/drag-and-drop/vue'
import { type Ref, type ShallowRef } from 'vue'

import { i18n } from '#shared/i18n/index.ts'
import { startAndEndEventsDNDPlugin } from '#shared/utils/startAndEndEventsDNDPlugin.ts'

import { useAnnouncer } from '#desktop/composables/accessibility/useAnnouncer.ts'

export const useAccessibleDragAndDrop = <T extends HTMLElement, C extends string>(
  parent: ShallowRef<T | null>,
  children: Ref<C[]>,
  options: {
    dndStartCallback?: (parent: HTMLElement) => void
    dndEndCallback?: (parent: HTMLElement) => void
    dropZoneClass?: string
    synthDropZoneClass?: string
    draggingClass?: string
  } = {},
) => {
  const {
    dndStartCallback = () => {},
    dndEndCallback = () => {},
    dropZoneClass = '',
    synthDropZoneClass = '',
    draggingClass = '',
  } = options

  const { announce } = useAnnouncer()

  dragAndDrop({
    // Wrong library bug it should be ShallowRef
    parent: parent as Ref<HTMLElement>,
    values: children,
    plugins: [startAndEndEventsDNDPlugin(dndStartCallback, dndEndCallback), animations()],
    dropZoneClass: `opacity-0 dragging-active ${dropZoneClass}`,
    synthDropZoneClass: `opacity-0 dragging-active ${synthDropZoneClass}`,
    draggingClass: `dragging-active ${draggingClass}`,
    onDragstart: (state) => {
      announce(i18n.t(`Drag started for %s.`, state.draggedNode.data.value as string))
    },
    onSort: (event) => {
      announce(
        i18n.t(
          'Sorted %s in user taskbar list to position %s.',
          event.draggedNodes[0].data.value as string,
          event.position + 1,
        ),
      )
    },
    onTransfer: (event) => {
      announce(
        i18n.t(
          'Transferred %s from user taskbar list %s at position %s.',
          event.draggedNodes[0].data.value as string,
          event.sourceParent.el === (parent as Ref<HTMLElement>).value ? 1 : 2, // Compare source parent element to our list parent to determine list index
          event.targetIndex + 1,
        ),
      )
    },
    onDragend: (state) => {
      announce(i18n.t('Drag ended for %s.', state.draggedNode.data.value as string))
    },
  })
}
