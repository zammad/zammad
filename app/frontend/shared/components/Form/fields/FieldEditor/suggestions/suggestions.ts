// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Content, Editor } from '@tiptap/core'
import type { SuggestionOptions } from '@tiptap/suggestion'
import { VueRenderer } from '@tiptap/vue-3'
import tippy, { type GetReferenceClientRect, type Instance } from 'tippy.js'
import { PluginKey } from 'prosemirror-state'

import MentionItem from '../SuggestionItem.vue'
import type { MentionType } from '../types'

interface MentionOptions<T> {
  activator: string
  type: MentionType
  items(props: { query: string; editor: Editor }): T[] | Promise<T[]>
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  insert(props: Record<string, any>): Content
}

export default function buildMentionExtension<T>(
  options: MentionOptions<T>,
): Omit<SuggestionOptions, 'editor'> {
  return {
    char: options.activator,
    items: options.items,
    pluginKey: new PluginKey(options.type),
    command: ({ editor, range, props }) => {
      // increase range.to by one when the next node is of type "text"
      // and starts with a space character
      const { nodeAfter } = editor.view.state.selection.$to
      const overrideSpace = nodeAfter?.text?.startsWith(' ')

      if (overrideSpace) {
        range.to += 1
      }

      editor.chain().focus().insertContentAt(range, options.insert(props)).run()
    },
    render() {
      let component: VueRenderer
      let popup: Instance

      return {
        onStart(props) {
          component = new VueRenderer(MentionItem, {
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
          component.updateProps({
            items: props.items,
            command: props.command,
            type: options.type,
          })
          popup.setProps({
            getReferenceClientRect: props.clientRect as GetReferenceClientRect,
          })
        },
        onKeyDown(props) {
          if (props.event.key === 'Escape') {
            popup.hide()
            return true
          }

          return component.ref?.onKeyDown(props)
        },
        onExit() {
          popup.destroy()
          component.destroy()
        },
      }
    },
  }
}
