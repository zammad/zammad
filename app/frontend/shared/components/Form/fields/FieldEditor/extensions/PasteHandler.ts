// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { Extension } from '@tiptap/core'
import { Plugin, PluginKey } from '@tiptap/pm/state'

import { claimInlineImages } from '#shared/components/Form/fields/FieldEditor/features/image-handler/inlineImageUploads.ts'
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

            // Inside a code block ProseMirror inserts the clipboard as plain text and keeps the
            //   line breaks, which is what we want there - our HTML cleanup would instead produce
            //   block level nodes a code block cannot hold, and the content would land after it.
            if (view.state.selection.$from.parent.type.spec.code) return false

            const content = clipboardData.getData('text/html')

            // If no HTML content, let ProseMirror handle plain text.
            if (!content) return false

            const imageExtensionEnabled = editor.extensionManager.extensions.some(
              (ext) => ext.name === 'image',
            )

            const cleanContent = htmlCleanup(content, !imageExtensionEnabled)

            event.preventDefault()

            if (imageExtensionEnabled) {
              const attributes = editor.options.editorProps.attributes as Record<string, string>
              claimInlineImages(attributes?.['data-form-id'], cleanContent)
            }

            editor.commands.insertContent(cleanContent)

            return true
          },
        },
      }),
    ]
  },
})
