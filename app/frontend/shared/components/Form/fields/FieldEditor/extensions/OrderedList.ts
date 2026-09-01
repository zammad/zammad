// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { OrderedList } from '@tiptap/extension-list'

// tiptap declares only `start` and `type` for an ordered list and drops every attribute its schema
//   does not know, so a list counting down lost its direction on the way into the editor and counted
//   up from the offset instead. `reversed` is on the sanitizer allowlist, so an inbound mail can
//   carry one, and quoting it has to keep the numbers it showed.
export default OrderedList.extend({
  addAttributes() {
    return {
      ...this.parent?.(),
      reversed: {
        default: false,
        parseHTML: (element) => element.hasAttribute('reversed'),
        renderHTML: (attributes) => (attributes.reversed ? { reversed: '' } : {}),
      },
      // tiptap parses a missing `start` and a `start="1"` into the same one, which for a list counting
      //   down are two different lists: one counts down from as many items as it holds, the other
      //   from one. Keep a record of which of the two it was, out of the markup itself.
      startExplicit: {
        default: false,
        rendered: false,
        parseHTML: (element) => element.hasAttribute('start'),
      },
    }
  },

  renderHTML(props) {
    const rendered = this.parent?.(props) as [string, Record<string, unknown>, number]
    const { start, startExplicit } = props.node.attrs

    // The parent leaves a `start` of one out, since counting up it changes nothing. Counting down it
    //   is the whole number, so put it back where the list was given it.
    if (!startExplicit || start !== 1) return rendered

    const [tag, attributes, content] = rendered

    return [tag, { ...attributes, start }, content]
  },
})
