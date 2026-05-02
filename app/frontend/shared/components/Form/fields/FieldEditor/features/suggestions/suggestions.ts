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
  allowSpaces?: boolean

  items(props: { query: string; editor: Editor }): T[] | Promise<T[]>

  // oxlint-disable-next-line no-explicit-any
  insert(props: Record<string, any>): Content | Promise<Content>
}

enum Type {
  'BeforeStart' = 'onBeforeStart',
  'Start' = 'onStart',
  'BeforeUpdate' = 'onBeforeUpdate',
  'Update' = 'onUpdate',
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

      const renderFn = (type: Type) => (props: SuggestionProps) => {
        const loading = type === Type.BeforeUpdate || type === Type.BeforeStart

        if (!component) {
          if (type === Type.Update) return // onUpdate hook can run after onExit call

          component = setFloatingPopover(
            getEditorComponents().suggestionList!,
            props.editor,
            {
              loading,
              query: props.query,
              items: props.items,
              command: props.command,
              type: options.type,
            },
            {
              onClose: () => {
                component = null
              },
            },
          )
        } else {
          component?.updateProps({
            loading,
            query: props.query,
            items: props.items,
            command: props.command,
            type: options.type,
          })
        }
      }

      const removeAndCleanupPopover = () => {
        component?.el?.remove()
        component?.destroy()
        component = null
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

          return component?.ref?.onKeyDown(props)
        },

        onExit() {
          removeAndCleanupPopover()
        },
      }
    },
  }
}
