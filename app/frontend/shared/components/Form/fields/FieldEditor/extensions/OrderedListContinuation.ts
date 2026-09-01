// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { Extension } from '@tiptap/core'
import { Plugin, PluginKey } from '@tiptap/pm/state'
import { Mapping } from '@tiptap/pm/transform'

import type { Node as ProseMirrorNode, ResolvedPos } from '@tiptap/pm/model'

export const ORDERED_LIST_CONTINUATION_NAME = 'orderedListContinuation'

const ORDERED_LIST_NAME = 'orderedList'

export const OrderedListContinuationPluginKey = new PluginKey(ORDERED_LIST_CONTINUATION_NAME)

const isReversed = (list: ProseMirrorNode) => list.attrs.reversed === true

/**
 * Number the first item of a list carries: the one the list was given, or, where it was given none,
 * one counting up and as many as it holds items counting down.
 */
const listStart = (list: ProseMirrorNode) =>
  isReversed(list) && !list.attrs.startExplicit ? list.childCount : (list.attrs.start as number)

/** Number a list behind `previous` carries on from, in the direction `previous` counts. */
const continuedStart = (previous: ProseMirrorNode, previousStart: number) =>
  previousStart + (isReversed(previous) ? -previous.childCount : previous.childCount)

/** Depth of the innermost ordered list around a position, `null` when it sits inside none. */
const orderedListDepth = ($position: ResolvedPos) =>
  Array.from({ length: $position.depth }, (_, index) => $position.depth - index).find(
    (depth) => $position.node(depth).type.name === ORDERED_LIST_NAME,
  ) ?? null

/**
 * Position, in the document before the transaction, of the ordered list a list now at `position` was
 * cut out of — `null` when it was not cut out of one.
 *
 * A fragment cut out of an earlier list maps back to a point *inside* that list, which is the shape
 * ProseMirror leaves behind after a split, no matter which command performed it — `Enter` on an empty
 * item, `liftListItem` from the toolbar, or a backspace at the start of an item. The head of the split
 * keeps the position of the list it came from, so it maps back to the point in front of it and has no
 * origin of its own. A list newly wrapped around existing content — toggling the list on, the escape
 * hatch that restarts numbering — maps back to that content and never into a list.
 */
const originListPosition = (
  position: number,
  toOldDocument: Mapping,
  oldDocument: ProseMirrorNode,
) => {
  const mapped = toOldDocument.map(position, 1)
  if (mapped < 0 || mapped > oldDocument.content.size) return null

  const $mapped = oldDocument.resolve(mapped)
  const depth = orderedListDepth($mapped)

  return depth === null ? null : $mapped.before(depth)
}

/**
 * Nearest ordered list in front of the given one that came out of the same list, skipping both what
 * the split left in between and any list it has nothing to do with. The head of the split kept the
 * position of that list, so it maps back onto the origin itself, while an earlier fragment shares it.
 */
const precedingFragment = (
  $list: ResolvedPos,
  origin: number,
  toOldDocument: Mapping,
  oldDocument: ProseMirrorNode,
) =>
  Array.from({ length: $list.index() }, (_, index) => ({
    node: $list.parent.child(index),
    position: $list.posAtIndex(index),
  })).findLast(
    ({ node, position }) =>
      node.type.name === ORDERED_LIST_NAME &&
      (toOldDocument.map(position, 1) === origin ||
        originListPosition(position, toOldDocument, oldDocument) === origin),
  ) ?? null

/** An ordered list in the document after the transaction, with the list it was cut out of. */
interface ListWithOrigin {
  node: ProseMirrorNode
  position: number
  origin: number | null
}

/**
 * Number to pin down for the head of a split, which is left alone otherwise: a reversed list counts
 * from as many as it holds items, so handing items over renumbers it, where a list counting up keeps
 * its one. Returns what its first item carried before the transaction, `null` for anything else.
 *
 * Losing items is not enough to tell a split from a list simply replaced by a shorter one, which
 * keeps the offset it was given. Only a list some fragment names as its origin handed items over.
 */
const keptReversedStart = (
  { node, position }: ListWithOrigin,
  toOldDocument: Mapping,
  oldDocument: ProseMirrorNode,
  origins: Set<number>,
) => {
  if (!isReversed(node)) return null

  const mapped = toOldDocument.map(position, 1)
  if (!origins.has(mapped)) return null

  const before = oldDocument.nodeAt(mapped)
  if (before?.type.name !== ORDERED_LIST_NAME || before.childCount <= node.childCount) return null

  return listStart(before)
}

/**
 * Keeps the original numbers when an ordered list is broken apart, so a quoted list can be answered
 * inline without its items silently renumbering from one.
 *
 * The number is worked out once, at the moment of the split, from the items still numbered in front
 * of it — an item lifted out of the list stops consuming a number, like it does on screen.
 */
export const OrderedListContinuation = Extension.create({
  name: ORDERED_LIST_CONTINUATION_NAME,

  addProseMirrorPlugins() {
    return [
      new Plugin({
        key: OrderedListContinuationPluginKey,

        appendTransaction: (transactions, oldState, newState) => {
          if (!transactions.some((transaction) => transaction.docChanged)) return null

          // Our own numbering never needs renumbering in turn.
          if (
            transactions.some((transaction) =>
              transaction.getMeta(OrderedListContinuationPluginKey),
            )
          )
            return null

          const mapping = new Mapping()
          transactions.forEach((transaction) => mapping.appendMapping(transaction.mapping))
          const toOldDocument = mapping.invert()

          const lists: ListWithOrigin[] = []

          newState.doc.descendants((node, position) => {
            // Lists never live inside a text block, so there is nothing to find below one.
            if (node.isTextblock) return false
            if (node.type.name !== ORDERED_LIST_NAME) return true

            lists.push({
              node,
              position,
              origin: originListPosition(position, toOldDocument, oldState.doc),
            })

            return true
          })

          // Which lists the split took items from is only on record in the fragments behind them, so
          // the head of one can only be told apart once every fragment is known.
          const origins = new Set(lists.flatMap(({ origin }) => (origin === null ? [] : [origin])))

          const updates: { position: number; start: number }[] = []

          // A single transaction can break a list into more than two fragments. The corrections are
          // only applied at the end, so a fragment has to read the number decided for the one in
          // front of it here, not the stale attribute still on the node.
          const decidedStarts = new Map<number, number>()

          const decidedStart = (list: ListWithOrigin) => {
            const { position, origin } = list
            if (origin === null)
              return keptReversedStart(list, toOldDocument, oldState.doc, origins)

            const previous = precedingFragment(
              newState.doc.resolve(position),
              origin,
              toOldDocument,
              oldState.doc,
            )
            if (!previous) return null

            return continuedStart(
              previous.node,
              decidedStarts.get(previous.position) ?? listStart(previous.node),
            )
          }

          lists.forEach((list) => {
            const start = decidedStart(list)
            if (start === null) return

            decidedStarts.set(list.position, start)

            if (start !== listStart(list.node)) updates.push({ position: list.position, start })
          })

          if (!updates.length) return null

          const { tr } = newState

          updates.forEach(({ position, start }) => {
            tr.setNodeAttribute(position, 'start', start)
            // The number is the list's own from here on, not one to work out from its items again.
            tr.setNodeAttribute(position, 'startExplicit', true)
          })

          return tr.setMeta(OrderedListContinuationPluginKey, true)
        },
      }),
    ]
  },
})

export default OrderedListContinuation
