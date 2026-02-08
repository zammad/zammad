// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { Table as TableTipTap } from '@tiptap/extension-table'
import { Plugin, PluginKey } from '@tiptap/pm/state'
import { columnResizingPluginKey } from '@tiptap/pm/tables'
import { VueRenderer, type Editor } from '@tiptap/vue-3'

import TableMenuTrigger, { triggerId } from '../../features/table/TableMenuTrigger.vue'
import { getActiveNodeOrMark, getReferenceClientRect } from '../../utils.ts'

const createTriggerComponent = (editor: Editor) =>
  new VueRenderer(TableMenuTrigger, { props: { editor }, editor })

const calculateTriggerPosition = (
  editor: Editor,
  triggerElement: HTMLButtonElement,
  tableWrapper: HTMLDivElement | null,
) => {
  const clientRect = getReferenceClientRect(editor)
  if (!clientRect) return

  const containerRect = tableWrapper?.getBoundingClientRect()
  if (!containerRect) return

  const padding = 2

  const topOffset = clientRect.top - containerRect.top + padding

  const isRtl = document.dir === 'rtl'

  const leftOffset = isRtl
    ? clientRect.left - containerRect.left + padding
    : clientRect.right - containerRect.left - triggerElement.clientWidth - padding

  triggerElement.style.left = `${leftOffset}px`
  triggerElement.style.top = `${topOffset}px`
}

const mountTriggerElement = (locatorElement: HTMLElement, triggerElement: HTMLButtonElement) => {
  locatorElement?.prepend(triggerElement)

  return triggerElement
}

const cleanupTriggers = (editorElement?: HTMLElement) => {
  editorElement?.querySelectorAll(`.tableWrapper #${triggerId}`).forEach((btn) => {
    btn.remove()
  })
}

export const Table = TableTipTap.extend({
  addProseMirrorPlugins() {
    const { editor, parent } = this as unknown as {
      editor: Editor
      parent: () => Plugin[]
    }

    const pluginKey = new PluginKey('table-trigger-button')

    return [
      ...parent(),
      new Plugin({
        key: pluginKey,
        state: {
          init() {
            return {
              triggerComponent: null as VueRenderer | null,
              isColumnResizing: false,
            }
          },
          apply(tr, value) {
            // creates once on first transaction and reuses it
            return tr.getMeta(pluginKey) || value
          },
        },
        filterTransaction: (tr) => {
          // Careful this will be called before a transaction is applied
          const editorElement = editor.options.element as HTMLElement

          // Remove all triggers on any transaction and re-render only the active one later.
          cleanupTriggers(editorElement)

          const pluginState = pluginKey.getState(editor.state)

          // Remember column resizing state, since view update may not get the same transaction metadata.
          pluginState.isColumnResizing = tr.getMeta(columnResizingPluginKey)?.setDragging ?? false

          // We don't need to show the trigger if:
          // - the table node is not active
          // - column resizing is active
          if (!editor.isActive(TableTipTap.name) || pluginState.isColumnResizing) return true

          // Create the component once, and store it as a plugin state.
          if (!pluginState.triggerComponent)
            pluginState.triggerComponent = createTriggerComponent(editor)

          return true
        },
        view() {
          return {
            update: (view) => {
              const pluginState = pluginKey.getState(view.state)

              const { triggerComponent, isColumnResizing } = pluginState

              // We don't need to show the trigger if:
              // - the table node is not active
              // - column resizing is active
              // - trigger component has not been initialized yet
              if (!editor.isActive(TableTipTap.name) || isColumnResizing || !triggerComponent)
                return

              const activeElement = getActiveNodeOrMark(editor)

              const tableWrapper = activeElement?.closest('.tableWrapper') as HTMLDivElement | null
              if (!tableWrapper) return // should not happen™

              // use existing trigger if present or mount a new one
              let triggerElement = tableWrapper?.querySelector(`#${triggerId}`) as HTMLButtonElement

              if (!triggerElement) {
                triggerElement = mountTriggerElement(
                  tableWrapper,
                  triggerComponent.element as HTMLButtonElement,
                )
              }

              // Position calculation has to happen AFTER the transaction is applied
              calculateTriggerPosition(editor, triggerElement, tableWrapper)
            },
          }
        },
        destroy() {
          const { triggerComponent } = pluginKey.getState(editor.state)
          triggerComponent?.destroy()
        },
      }),
    ]
  },
})
