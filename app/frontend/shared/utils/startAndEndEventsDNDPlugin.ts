// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { DNDPlugin } from '@formkit/drag-and-drop'

export const startAndEndEventsDNDPlugin =
  (
    startCallback?: (parent: HTMLElement, event: DragEvent) => void,
    endCallback?: (parent: HTMLElement) => void,
  ): DNDPlugin =>
  (parent) => {
    const dragStart = (event: DragEvent) => {
      startCallback?.(parent, event)
    }

    const dragEnd = () => {
      endCallback?.(parent)
    }

    return {
      setupNode: (data) => {
        data.node.addEventListener('dragstart', dragStart)
        data.node.addEventListener('dragend', dragEnd)
      },
      tearDownNode: (data) => {
        data.node.removeEventListener('dragstart', dragStart)
        data.node.removeEventListener('dragend', dragEnd)
      },
    }
  }
