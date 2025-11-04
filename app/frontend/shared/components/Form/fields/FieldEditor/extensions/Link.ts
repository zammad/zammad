// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import Link from '@tiptap/extension-link'
import { Plugin } from '@tiptap/pm/state'
import { type Editor, VueRenderer } from '@tiptap/vue-3'

// We can't async load LinkForm, otherwise initially VueRenderer will not render it
import LinkForm from '#shared/components/Form/fields/FieldEditor/features/link/LinkForm.vue'
import { PLUGIN_NAME } from '#shared/components/Form/fields/FieldEditor/features/link/types.ts'
import {
  getActiveNodeOrMark,
  setFloatingPopover,
} from '#shared/components/Form/fields/FieldEditor/utils.ts'
import { useAppName } from '#shared/composables/useAppName.ts'
import getUuid from '#shared/utils/getUuid.ts'

const appName = useAppName()

export default Link.extend({
  inclusive: false, // prevents bad UX to leave setting a link on the same line.

  name: PLUGIN_NAME,

  addAttributes() {
    const attributes = {
      href: {
        default: null,
        parseHTML: (element: HTMLLinkElement) => element.getAttribute('href'),
        renderHTML: (attributes: Record<string, string>) => ({ href: attributes.href }),
      },
    }

    if (appName === 'desktop') {
      // Desktop has a link form, so we need to add ARIA attributes
      return {
        ...attributes,
        'aria-haspopup': { default: 'dialog' },
        'aria-expanded': { default: 'false' },
        'aria-controls': { default: null },
      }
    }

    return attributes
  },

  addCommands() {
    let linkComponent: VueRenderer | null = null
    let activeLinkMarkElement: HTMLLinkElement | null = null

    const setAriaLabels = (id: string) => {
      const linkMark = getActiveNodeOrMark(this.editor)

      if (!linkMark) return
      activeLinkMarkElement = linkMark as HTMLLinkElement

      linkMark.setAttribute('aria-expanded', 'true')
      linkMark.setAttribute('aria-controls', id)
    }

    const unsetAriaLabels = () => {
      if (!activeLinkMarkElement) return

      activeLinkMarkElement.setAttribute('aria-expanded', 'false')
      activeLinkMarkElement.removeAttribute('aria-controls')

      activeLinkMarkElement = null
    }

    const destroyLinkForm = () => {
      if (!linkComponent) return

      linkComponent.element?.remove()
      linkComponent.destroy()
      linkComponent = null

      unsetAriaLabels()
    }

    return {
      openLinkForm:
        () =>
        ({ editor }: { editor: Editor }) => {
          const { state } = editor
          const { from, to } = state.selection

          const id = getUuid() // used to connect the link mark with the popover

          setAriaLabels(id)

          linkComponent = setFloatingPopover(
            LinkForm,
            editor,
            {
              from,
              to,
              id,
            },
            {
              onClose: () => {
                editor.commands.closeLinkForm()
              },
            },
          )

          return true
        },
      closeLinkForm: () => () => {
        destroyLinkForm()
        return false
      },
    }
  },

  addProseMirrorPlugins() {
    const { editor, parent } = this as unknown as {
      editor: Editor
      parent: () => (typeof Plugin)[]
    }

    return [
      ...(parent?.() || []), // include parent plugins if any
      appName === 'desktop' //  Only desktop has the link form
        ? new Plugin({
            props: {
              handleKeyDown() {
                return editor.commands.closeLinkForm()
              },
              handleClick() {
                const isLinkClicked = editor.getAttributes(PLUGIN_NAME)
                editor.commands.closeLinkForm()

                if ('href' in isLinkClicked) editor.commands.openLinkForm()

                return false
              },
            },
          })
        : new Plugin({}),
    ]
  },
}).configure({
  openOnClick: appName !== 'desktop', // Only desktop for now
})
