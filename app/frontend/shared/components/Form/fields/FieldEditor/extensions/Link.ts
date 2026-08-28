// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Link from '@tiptap/extension-link'
import { Plugin } from '@tiptap/pm/state'
import { type Editor, VueRenderer } from '@tiptap/vue-3'

import { ANSWER_LINK_TARGET_TYPE } from '#shared/components/Form/fields/FieldEditor/features/link/answerLink.ts'
// We can't async load LinkForm, otherwise initially VueRenderer will not render it
import LinkForm from '#shared/components/Form/fields/FieldEditor/features/link/LinkForm.vue'
import {
  EXTENSION_NAME,
  type LinkFormVariant,
} from '#shared/components/Form/fields/FieldEditor/features/link/types.ts'
import {
  getActiveNodeOrMark,
  setFloatingPopover,
} from '#shared/components/Form/fields/FieldEditor/utils.ts'
import { getEditorComponents } from '#shared/components/Form/initializeFieldEditor.ts'
import { useAppName } from '#shared/composables/useAppName.ts'
import getUuid from '#shared/utils/getUuid.ts'

const appName = useAppName()

export default Link.extend({
  inclusive: false, // prevents bad UX to leave setting a link on the same line.

  name: EXTENSION_NAME,

  addAttributes() {
    const attributes = {
      href: {
        default: null,
        parseHTML: (element: HTMLLinkElement) => element.getAttribute('href'),
        renderHTML: (attributes: Record<string, string>) => ({ href: attributes.href }),
      },
      // Marker of a link to a knowledge base answer. The stored `href` is never trusted on read:
      //   `KnowledgeBaseRichText.resolve_answer_links` looks the target up by these two and
      //   rewrites the `href` per consumer. Losing them on a round trip turns the link dead.
      //
      // Parsed and rendered explicitly to keep both values strings, and to stay off an ordinary
      //   link: the default handling coerces a numeric id and writes the attribute out as `null`.
      'data-target-type': {
        default: null,
        parseHTML: (element: HTMLLinkElement) => element.getAttribute('data-target-type'),
        renderHTML: (attributes: Record<string, string>) =>
          attributes['data-target-type']
            ? { 'data-target-type': attributes['data-target-type'] }
            : {},
      },
      'data-target-id': {
        default: null,
        parseHTML: (element: HTMLLinkElement) => element.getAttribute('data-target-id'),
        renderHTML: (attributes: Record<string, string>) =>
          attributes['data-target-id'] ? { 'data-target-id': attributes['data-target-id'] } : {},
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

    // The knowledge base answer flavour is built on a desktop-only autocomplete field, so it is
    //   only known here through the component registry the app fills in.
    const linkForm = (variant: LinkFormVariant) =>
      variant === 'knowledgeBaseAnswer'
        ? getEditorComponents().knowledgeBaseAnswerLinkForm
        : LinkForm

    return {
      openLinkForm:
        (variant = 'url') =>
        () => {
          const form = linkForm(variant)

          if (!form) return false

          const { state } = this.editor
          const { from, to } = state.selection

          const id = getUuid() // used to connect the link mark with the popover

          setAriaLabels(id)

          linkComponent = setFloatingPopover(
            form,
            this.editor,
            {
              from,
              to,
              id,
            },
            {
              onClose: () => {
                this.editor.commands.closeLinkForm()
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
      parent: () => Plugin[]
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
                const clickedLink = editor.getAttributes(EXTENSION_NAME)
                editor.commands.closeLinkForm()

                // A link to a knowledge base answer is edited with the answer picker rather than
                //   as a URL; its marker attribute is what gives it away.
                if ('href' in clickedLink)
                  editor.commands.openLinkForm(
                    clickedLink['data-target-type'] === ANSWER_LINK_TARGET_TYPE
                      ? 'knowledgeBaseAnswer'
                      : 'url',
                  )

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
