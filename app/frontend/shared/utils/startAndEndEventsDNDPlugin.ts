// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
        if (data.node.el) {
          // Safety in case it is accessed like this
          data.node.el.addEventListener('dragstart', dragStart)
          data.node.el.addEventListener('dragend', dragEnd)
          return
        }
        /**
         * This is a workaround.
         * The formkit ts declaration seems to be not correct it expects a SetupNodeData where the node is of type NodeRecord
         * @NodeRecord type is not yielding the node property under the `el` property
         * @interface NodeRecord<T> {
         *     el: Node;
         *     data: NodeData<T>;
         * } NodeRecord = HTMLElement in this case
         * :TODO Evaluate and add maybe issue to the library
         * @link https://github.com/formkit/drag-and-drop/issues
         * */
        const { node } = data as unknown as Record<'node', HTMLElement>
        node.addEventListener('dragstart', dragStart)
        node.addEventListener('dragend', dragEnd)
      },
      tearDownNode: (data) => {
        if (data.node.el) {
          // Safety in case it is accessed like this
          data.node.el.removeEventListener('dragstart', dragStart)
          data.node.el.removeEventListener('dragend', dragEnd)
          return
        }

        const { node } = data as unknown as Record<'node', HTMLElement>

        node.removeEventListener('dragstart', dragStart)
        node.removeEventListener('dragend', dragEnd)
      },
    }
  }
