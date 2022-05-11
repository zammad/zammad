// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import Image from '@tiptap/extension-image'

// TODO images should be resizable
export default Image.extend({
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
