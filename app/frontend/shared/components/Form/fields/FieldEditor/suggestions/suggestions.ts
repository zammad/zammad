// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Content, Editor } from '@tiptap/core'
import type { SuggestionOptions } from '@tiptap/suggestion'
import { VueRenderer } from '@tiptap/vue-3'
import tippy, { type GetReferenceClientRect, type Instance } from 'tippy.js'
import { PluginKey } from '@tiptap/pm/state'

import SuggestionsList from '../SuggestionsList.vue'
import type { MentionType } from '../types'

interface MentionOptions<T> {
  activator: string
  type: MentionType
  allowSpaces?: boolean
  items(props: { query: string; editor: Editor }): T[] | Promise<T[]>
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  insert(props: Record<string, any>): Content | Promise<Content>
}

export default function buildMentionExtension<T>(
  options: MentionOptions<T>,
): Omit<SuggestionOptions, 'editor'> {
  return {
    char: options.activator,
    allowSpaces: options.allowSpaces,
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
      let component: VueRenderer
      let popup: Instance
      let mounted = false

      return {
        onStart(props) {
          mounted = true
          component = new VueRenderer(SuggestionsList, {
            props: {
              items: props.items,
              command: props.command,
              type: options.type,
            },
            editor: props.editor,
          })
          ;[popup] = tippy('body', {
            getReferenceClientRect: props.clientRect as GetReferenceClientRect,
            appendTo: () => document.body,
            content: component.element,
            showOnCreate: true,
            interactive: true,
            trigger: 'manual',
            placement: 'bottom-start',
          })
        },
        onUpdate(props) {
          if (!mounted) return
          component.updateProps({
            items: props.items,
            command: props.command,
            type: options.type,
          })
          popup.show()
          popup.setProps({
            getReferenceClientRect: props.clientRect as GetReferenceClientRect,
          })
        },
        onKeyDown(props) {
          if (!mounted) return false

          if (props.event.key === 'Escape') {
            popup.hide()
            return true
          }

          return component.ref?.onKeyDown(props)
        },
        onExit() {
          mounted = false
          popup.destroy()
          component.destroy()
        },
      }
    },
  }
}
