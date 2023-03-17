// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import Image from '@tiptap/extension-image'
import { VueNodeViewRenderer } from '@tiptap/vue-3'
import ImageResizable from '../ImageResizable.vue'

export default Image.extend({
  addAttributes() {
    return {
      ...this.parent?.(),

      width: {
        default: '100%',
        renderHTML: (attributes) => {
          return {
            width: attributes.width,
          }
        },
      },

      height: {
        default: 'auto',
        renderHTML: (attributes) => {
          return {
            height: attributes.height,
          }
        },
      },

      isDraggable: {
        default: true,
        renderHTML: () => {
          return {}
        },
      },
    }
  },
  addNodeView() {
    return VueNodeViewRenderer(ImageResizable)
  },
  addCommands() {
    return {
      setImages:
        (attributes) =>
        ({ chain }) => {
          return chain()
            .focus()
            .insertContent([
              ...attributes.map((image) => ({
                type: 'image',
                attrs: {
                  src: image.content,
                  alt: image.name,
                },
              })),
              {
                type: 'paragraph',
              },
            ])
            .run()
        },
    }
  },
}).configure({
  inline: true,
  allowBase64: true,
})
