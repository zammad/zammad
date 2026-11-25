// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { Extension } from '@tiptap/core'
import { Plugin, PluginKey } from '@tiptap/pm/state'

const isSubmitPress = (event: KeyboardEvent) =>
  event.key === 'Enter' && (event.ctrlKey || event.metaKey) && !event.shiftKey && !event.altKey

// ProseMirror takes every press of Enter for itself, also with a modifier, so the combinations
//   that submit the form around the editor are handed on to the page as a press of their own.
//   Unless the page takes it, the press is left to the editor as before.
export default Extension.create({
  name: 'formSubmitKeys',

  // Ahead of the hard break's own `Mod-Enter` and of the suggestion popups.
  priority: 1000,

  addProseMirrorPlugins() {
    return [
      new Plugin({
        key: new PluginKey('formSubmitKeys'),
        props: {
          handleKeyDown(_view, event) {
            if (!isSubmitPress(event)) return false

            const press = new KeyboardEvent('keydown', {
              key: event.key,
              code: event.code,
              ctrlKey: event.ctrlKey,
              metaKey: event.metaKey,
              repeat: event.repeat,
              cancelable: true,
            })

            return !window.dispatchEvent(press)
          },
        },
      }),
    ]
  },
})
