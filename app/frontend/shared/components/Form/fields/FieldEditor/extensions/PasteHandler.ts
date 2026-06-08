// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { Extension } from '@tiptap/core'
import { Plugin, PluginKey } from '@tiptap/pm/state'

import { htmlCleanup } from '#shared/utils/htmlCleanup.ts'

export const PasteHandlerPluginKey = new PluginKey('paste-handler')

export const PasteHandler = Extension.create({
  name: 'paste-handler',

  addProseMirrorPlugins() {
    const { editor } = this

    return [
      new Plugin({
        key: PasteHandlerPluginKey,
        props: {
          handlePaste: (view, event) => {
            const { clipboardData } = event
            if (!clipboardData) return false

            const content = clipboardData.getData('text/html')

            // If no HTML content, let ProseMirror handle plain text.
            if (!content) return false

            const imageExtensionEnabled = editor.extensionManager.extensions.some(
              (ext) => ext.name === 'image',
            )

            const cleanContent = htmlCleanup(content, !imageExtensionEnabled)

            event.preventDefault()

            editor.commands.insertContent(cleanContent)

            return true
          },
        },
      }),
    ]
  },
})
