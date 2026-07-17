// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { PluginKey } from '@tiptap/pm/state'
import { VueRenderer } from '@tiptap/vue-3'

import type { MentionType } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { setFloatingPopover } from '#shared/components/Form/fields/FieldEditor/utils.ts'
import { getEditorComponents } from '#shared/components/Form/initializeFieldEditor.ts'

import type { Content, Editor } from '@tiptap/core'
import type { SuggestionOptions, SuggestionProps } from '@tiptap/suggestion'

interface MentionOptions<T> {
  activator: string
  type: MentionType
  label: string
  placeholder: string
  allowSpaces?: boolean
  // Whether the type returns results for an empty query (i.e. shows a default
  // list on open). Such types get a loading state on open; query-driven types
  // show their placeholder immediately instead.
  showsDefaultList?: boolean

  items(props: { query: string; editor: Editor }): T[] | Promise<T[]>

  // oxlint-disable-next-line no-explicit-any
  insert(props: Record<string, any>): Content | Promise<Content>
}

enum Type {
  BeforeStart = 'onBeforeStart',
  Start = 'onStart',
  BeforeUpdate = 'onBeforeUpdate',
  Update = 'onUpdate',
}

let listboxIdCounter = 0

const setEditorAttr = (editor: Editor, name: string, value: string | null) => {
  const dom = editor?.view?.dom
  if (!dom) return
  if (value === null) dom.removeAttribute(name)
  else dom.setAttribute(name, value)
}

export default function buildMentionExtension<T>(
  options: MentionOptions<T>,
): Omit<SuggestionOptions, 'editor'> {
  return {
    char: options.activator,
    allowSpaces: options.allowSpaces ?? true,
    items: options.items,
    pluginKey: new PluginKey(options.type),
    command({ editor, range, props }) {
      // increase range.to by one when the next node is of type "text"
      // and starts with a space character
      const { nodeAfter } = editor.view.state.selection.$to
      const overrideSpace = nodeAfter?.text?.startsWith(' ')

      // activators start with a space, so we need to decrease the range
      range.from -= 1
      if (overrideSpace) {
        range.to += 1
      }

      const insert = (content: Content) => {
        editor.chain().focus().insertContentAt(range, content).run()
      }

      const content = options.insert(props)

      if (content instanceof Promise) {
        content.then((c) => insert(c))
      } else {
        insert(content)
      }
    },
    render() {
      let component: VueRenderer | null
      let listboxId: string | null = null
      let editor: Editor | null = null
      let itemCount = 0
      let lastItems: SuggestionProps['items'] = []

      const syncActiveDescendant = () => {
        if (!editor || !listboxId) return
        const idx = component?.ref?.selectedIndex ?? 0
        if (itemCount > 0 && idx >= 0 && idx < itemCount) {
          setEditorAttr(editor, 'aria-activedescendant', `${listboxId}-option-${idx}`)
        } else {
          setEditorAttr(editor, 'aria-activedescendant', null)
        }
      }

      const removeAndCleanupPopover = () => {
        if (editor) {
          setEditorAttr(editor, 'aria-controls', null)
          setEditorAttr(editor, 'aria-expanded', null)
          setEditorAttr(editor, 'aria-haspopup', null)
          setEditorAttr(editor, 'aria-activedescendant', null)
        }
        component?.el?.remove()
        component?.destroy()
        component = null
        listboxId = null
        editor = null
        itemCount = 0
        lastItems = []
      }

      const renderFn = (type: Type) => (props: SuggestionProps) => {
        // Query updates are always a loading state. The initial open is only a
        // loading state for types that show a default list — otherwise it would
        // just flash before the placeholder of a query-driven type.
        const loading =
          type === Type.BeforeUpdate || (type === Type.BeforeStart && !!options.showsDefaultList)

        // Keep the last settled items visible while a new query loads, so the
        // list doesn't flash empty (or "no results") between keystrokes. Only
        // adopt the incoming items once the query has settled.
        if (!loading) lastItems = props.items
        const items = loading ? lastItems : props.items

        if (!component) {
          if (type === Type.Update) return // onUpdate hook can run after onExit call

          listboxId = `mention-listbox-${++listboxIdCounter}`
          ;({ editor } = props)

          component = setFloatingPopover(
            getEditorComponents().suggestionList!,
            props.editor,
            {
              loading,
              query: props.query,
              items,
              command: props.command,
              type: options.type,
              label: options.label,
              placeholder: options.placeholder,
              listboxId,
            },
            {
              onClose: removeAndCleanupPopover,
            },
          )

          setEditorAttr(props.editor, 'aria-controls', listboxId)
          setEditorAttr(props.editor, 'aria-expanded', 'true')
          setEditorAttr(props.editor, 'aria-haspopup', 'listbox')
        } else {
          component?.updateProps({
            loading,
            query: props.query,
            items,
            command: props.command,
            type: options.type,
            listboxId,
          })
        }

        itemCount = items.length
        syncActiveDescendant()
      }

      return {
        onBeforeStart: renderFn(Type.BeforeStart), // loading = true
        onStart: renderFn(Type.Start), // loading = false
        onBeforeUpdate: renderFn(Type.BeforeUpdate), // loading = true
        onUpdate: renderFn(Type.Update), // loading = false

        onKeyDown(props) {
          if (props.event.key === 'Escape') {
            removeAndCleanupPopover()
            return true
          }

          const handled = component?.ref?.onKeyDown(props)
          syncActiveDescendant()
          return handled
        },

        onExit() {
          removeAndCleanupPopover()
        },
      }
    },
  }
}
