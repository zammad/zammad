// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { PluginKey } from '@tiptap/pm/state'
import { VueRenderer } from '@tiptap/vue-3'
import { watch, type WatchSource, type WatchStopHandle } from 'vue'

import {
  claimInlineImages,
  getEditorFormId,
  inlineImageUploadsPluginKey,
} from '#shared/components/Form/fields/FieldEditor/features/image-handler/inlineImageUploads.ts'
import { SUGGESTIONS_LOADING_ATTRIBUTE } from '#shared/components/Form/fields/FieldEditor/features/suggestions/constants.ts'
import type { MentionType } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { setFloatingPopover } from '#shared/components/Form/fields/FieldEditor/utils.ts'
import { getEditorComponents } from '#shared/components/Form/initializeFieldEditor.ts'

import type { Content, Editor, EditorEvents } from '@tiptap/core'
import type { SuggestionOptions, SuggestionProps } from '@tiptap/suggestion'

interface MentionOptions<T> {
  activator: string
  type: MentionType
  label: string
  placeholder: string
  allowSpaces?: boolean
  // Whether the type returns results for an empty query (i.e. shows a default
  // list on open). Such types get a loading state on open; query-driven types
  // show their placeholder immediately instead.
  showsDefaultList?: boolean
  // Reactive source of the list for an empty query. The suggestion plugin asks for items only when
  // the query changes, so a change of this source refreshes such a list while it is open.
  defaultListSource?: WatchSource

  items(props: { query: string; editor: Editor }): T[] | Promise<T[]>

  // Content that loads asks `isStillWanted` before it leaves anything else behind, like attachments.
  insert(
    // oxlint-disable-next-line no-explicit-any
    props: Record<string, any>,
    isStillWanted: () => boolean,
  ): Content | Promise<Content>
}

enum Type {
  BeforeStart = 'onBeforeStart',
  Start = 'onStart',
  BeforeUpdate = 'onBeforeUpdate',
  Update = 'onUpdate',
}

let listboxIdCounter = 0

const setEditorAttr = (editor: Editor, name: string, value: string | null) => {
  const dom = editor?.view?.dom
  if (!dom) return
  if (value === null) dom.removeAttribute(name)
  else dom.setAttribute(name, value)
}

export default function buildMentionExtension<T>(
  options: MentionOptions<T>,
): Omit<SuggestionOptions, 'editor'> {
  // A query overtaken by the next one settles early with the entries of the one before, so the
  //   entries are only current once no query is left open.
  let openQueries = 0

  const items: MentionOptions<T>['items'] = async (props) => {
    openQueries += 1
    setEditorAttr(props.editor, SUGGESTIONS_LOADING_ATTRIBUTE, 'true')

    try {
      return await options.items(props)
    } finally {
      openQueries -= 1
      if (!openQueries) setEditorAttr(props.editor, SUGGESTIONS_LOADING_ATTRIBUTE, null)
    }
  }

  return {
    char: options.activator,
    allowSpaces: options.allowSpaces ?? true,
    items,
    pluginKey: new PluginKey(options.type),
    command({ editor, range, props }) {
      // increase range.to by one when the next node is of type "text"
      // and starts with a space character
      const { nodeAfter } = editor.view.state.selection.$to
      const overrideSpace = nodeAfter?.text?.startsWith(' ')

      // Activators start with a space, so the replaced range starts one earlier. A copy: the range
      //   belongs to the open list, which stays open for another pick when the content is refused.
      let replacedRange = {
        from: range.from - 1,
        to: overrideSpace ? range.to + 1 : range.to,
      }

      // The search itself: the replaced range may outlive it with the space before it.
      let searchRange = { from: range.from, to: range.to }

      const insert = (content: Content, takeFocus = true) => {
        // Images of an inserted text module or answer belong to this draft, like pasted ones -
        //   where the editor uploads its images at all.
        if (typeof content === 'string' && inlineImageUploadsPluginKey.get(editor.state))
          claimInlineImages(getEditorFormId(editor), content)

        const chain = takeFocus ? editor.chain().focus() : editor.chain()

        // Where the search opens a line, the range starts before the line, and text written at its
        //   start while the content loaded lies in between. That text stays.
        const from =
          searchRange.from - replacedRange.from > 1 ? searchRange.from : replacedRange.from

        chain.insertContentAt({ from, to: replacedRange.to }, content).run()
      }

      // Nothing left to replace once the search text is gone, e.g. deleted or sent, or the editor is.
      const isStillWanted = () => !editor.isDestroyed && searchRange.from !== searchRange.to

      const content = options.insert(props, isStillWanted)

      if (!(content instanceof Promise)) {
        insert(content)
        return
      }

      // While the content loads, the ranges follow what is written meanwhile; text typed at either
      //   edge stays outside of them.
      const trackRange = ({ transaction, appendedTransactions }: EditorEvents['transaction']) => {
        const follow = ({ from, to }: typeof replacedRange, { mapping }: typeof transaction) => {
          const mappedFrom = mapping.map(from)

          return { from: mappedFrom, to: Math.max(mappedFrom, mapping.map(to, -1)) }
        }

        ;[transaction, ...appendedTransactions].forEach((tr) => {
          replacedRange = follow(replacedRange, tr)
          searchRange = follow(searchRange, tr)
        })
      }

      editor.on('transaction', trackRange)

      // Loaded content leaves the focus where the writer has moved to meanwhile, e.g. another chat.
      const hasFocusMovedOn = () => {
        const { activeElement } = document

        return (
          !!activeElement &&
          activeElement !== document.body &&
          !editor.view.dom.contains(activeElement)
        )
      }

      content
        .then((loaded) => {
          if (isStillWanted()) insert(loaded, !hasFocusMovedOn())
        })
        // A failed request is already notified where the content is loaded, and leaves the search.
        .catch(() => {})
        .finally(() => editor.off('transaction', trackRange))
    },
    render() {
      let component: VueRenderer | null
      let listboxId: string | null = null
      let editor: Editor | null = null
      let itemCount = 0
      let lastProps: SuggestionProps | null = null
      let stopDefaultListWatch: WatchStopHandle | undefined

      const syncActiveDescendant = () => {
        if (!editor || !listboxId) return
        const idx = component?.ref?.selectedIndex ?? 0
        if (itemCount > 0 && idx >= 0 && idx < itemCount) {
          setEditorAttr(editor, 'aria-activedescendant', `${listboxId}-option-${idx}`)
        } else {
          setEditorAttr(editor, 'aria-activedescendant', null)
        }
      }

      const removeAndCleanupPopover = () => {
        if (editor) {
          setEditorAttr(editor, 'aria-controls', null)
          setEditorAttr(editor, 'aria-expanded', null)
          setEditorAttr(editor, 'aria-haspopup', null)
          setEditorAttr(editor, 'aria-activedescendant', null)
        }
        stopDefaultListWatch?.()
        stopDefaultListWatch = undefined
        component?.el?.remove()
        component?.destroy()
        component = null
        listboxId = null
        editor = null
        itemCount = 0
        lastProps = null
      }

      const refreshDefaultList = async () => {
        const props = lastProps
        if (!props || props.query) return

        const items = await options.items({ query: '', editor: props.editor })

        // The plugin has rendered or closed the list in the meantime.
        if (props !== lastProps || !component) return

        itemCount = items.length
        component.updateProps({ loading: false, items })
        syncActiveDescendant()
      }

      const renderFn = (type: Type) => (props: SuggestionProps) => {
        lastProps = props

        // Query updates are always a loading state. The initial open is only a
        // loading state for types that show a default list — otherwise it would
        // just flash before the placeholder of a query-driven type.
        // The plugin also updates once before it asks for the entries of a typed term, with none and
        // marked as loading: no finished search. An empty term keeps its hint, it never shows "No
        // results found".
        const isAskingForEntries = !!props.loading && !!props.query

        const loading =
          type === Type.BeforeUpdate ||
          (type === Type.BeforeStart && !!options.showsDefaultList) ||
          isAskingForEntries

        // No entries while a query loads: those of the query before are not current, and the list
        //   shows its loading indicator instead.
        const items = loading ? [] : props.items

        if (!component) {
          if (type === Type.Update) return // onUpdate hook can run after onExit call

          listboxId = `mention-listbox-${++listboxIdCounter}`
          ;({ editor } = props)

          component = setFloatingPopover(
            getEditorComponents().suggestionList!,
            props.editor,
            {
              loading,
              query: props.query,
              items,
              command: props.command,
              type: options.type,
              label: options.label,
              placeholder: options.placeholder,
              listboxId,
            },
            {
              onClose: removeAndCleanupPopover,
            },
          )

          setEditorAttr(props.editor, 'aria-controls', listboxId)
          setEditorAttr(props.editor, 'aria-expanded', 'true')
          setEditorAttr(props.editor, 'aria-haspopup', 'listbox')

          if (options.defaultListSource)
            stopDefaultListWatch = watch(options.defaultListSource, refreshDefaultList)
        } else {
          component?.updateProps({
            loading,
            query: props.query,
            items,
            command: props.command,
            type: options.type,
            listboxId,
          })
        }

        itemCount = items.length
        syncActiveDescendant()
      }

      return {
        onBeforeStart: renderFn(Type.BeforeStart),
        onStart: renderFn(Type.Start),
        onBeforeUpdate: renderFn(Type.BeforeUpdate),
        onUpdate: renderFn(Type.Update),

        onKeyDown(props) {
          if (props.event.key === 'Escape') {
            removeAndCleanupPopover()
            return true
          }

          const handled = component?.ref?.onKeyDown(props)
          syncActiveDescendant()
          return handled
        },

        onExit() {
          removeAndCleanupPopover()
        },
      }
    },
  }
}
