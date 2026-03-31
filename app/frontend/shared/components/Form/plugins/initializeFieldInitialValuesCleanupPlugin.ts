// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { cloneAny } from '@formkit/utils'

import type { FormFieldValue } from '../types.ts'
import type { FormKitNode } from '@formkit/core'

// FormKit determines dirty state by comparing _init (initial values snapshot) against
// _value (current values). When fields are dynamically added or removed — e.g. via
// core workflow toggling field visibility with "show" — FormKit updates _value but
// never syncs _init. This mismatch causes the form to appear dirty even though no
// user edit occurred.
//
// The _init object exists at every level of the node tree (form, groups) and contains
// nested snapshots. When a field inside a group changes, both the group's _init
// AND the form's _init (which nests the group's snapshot) must be updated.
//
// This plugin fixes the problem by:
// - On child removal: deleting the field's key from _init at the direct parent
//   and all ancestor levels, so _init stays in sync with _value.
// - On child re-add: restoring the previously saved _init value, so that toggling
//   a field off and back on doesn't lose the baseline for dirty comparison.
// - On new child: syncing the child's initial value into ancestor _init after it
//   settles, covering fields shown for the first time after the form settled.
// - On reset: clearing saved values, since reset() overwrites _init entirely.
const initializeFieldInitialValuesCleanupPlugin = (node: FormKitNode) => {
  if (node.type !== 'group') return

  // Stores _init values of removed children so they can be restored when the
  // same field is re-added (e.g. core workflow toggles a field off then back on).
  // Cleared on reset because reset() sets a fresh _init, making saved values stale.
  const savedInitValues = new Map<string, FormFieldValue>()

  // Re-evaluates the dirty state for this node and all ancestors.
  // Required because FormKit's removeChild() triggers the dirty check (touch)
  // BEFORE emitting childRemoved — so by the time our plugin cleans _init,
  // the dirty state was already set based on the stale _init.
  const reevaluateDirtyState = () => {
    node.context?.handlers?.touch()

    let ancestor = node.parent
    while (ancestor) {
      ancestor.context?.handlers?.touch()
      ancestor = ancestor.parent
    }
  }

  // Navigates into a nested object following a path of keys.
  // Returns the nested object at the end of the path, or undefined if any
  // segment is missing or not an object.
  const resolveNestedInit = (root: Record<string, unknown>, path: string[]) => {
    return path.reduce<Record<string, unknown> | undefined>((target, segment) => {
      if (target?.[segment] && typeof target[segment] === 'object') {
        return target[segment] as Record<string, unknown>
      }
      return undefined
    }, root)
  }

  // Applies an operation to the nested _init object at every ancestor level.
  // For a tree like form → group "ticket" → field "priority", removing "priority"
  // must clean both group._init.priority and form._init.ticket.priority.
  const walkAncestors = (operation: (target: Record<string, unknown>) => void) => {
    let ancestor = node.parent
    const path: string[] = [node.name]

    while (ancestor) {
      if (ancestor.props._init && typeof ancestor.props._init === 'object') {
        const target = resolveNestedInit(ancestor.props._init, path)
        if (target) operation(target)
      }

      path.unshift(ancestor.name)
      ancestor = ancestor.parent
    }
  }

  node.on('childRemoved', ({ payload: child }) => {
    if (
      node.props._init &&
      typeof node.props._init === 'object' &&
      child.name in node.props._init
    ) {
      savedInitValues.set(child.name, node.props._init[child.name])
      delete node.props._init[child.name]
    }

    walkAncestors((target) => {
      if (child.name in target) {
        delete target[child.name]
      }
    })

    reevaluateDirtyState()
  })

  node.on('child', ({ payload: child }) => {
    // Re-add of a previously removed field: restore the saved _init value
    // immediately at this level and all ancestors.
    if (savedInitValues.has(child.name)) {
      const savedValue = savedInitValues.get(child.name)
      savedInitValues.delete(child.name)

      if (node.props._init && typeof node.props._init === 'object') {
        node.props._init[child.name] = savedValue
      }

      walkAncestors((target) => {
        target[child.name] = savedValue
      })

      reevaluateDirtyState()
      return
    }

    // New field shown for the first time (e.g. initially hidden, then revealed
    // by core workflow after the form already settled). FormKit's addChild
    // updates _value but not _init at ancestor levels. Wait for the child to
    // settle so its value is final, then sync into ancestor _init.
    child.settled.then(() => {
      // Guard against the child or parent being destroyed before settle resolves
      // (e.g. rapid field toggling).
      if (!child.context || !node.context) return

      if (!node.props._init || typeof node.props._init !== 'object') return

      // Deep-clone here (after settle) so we capture the fully resolved value,
      // including any async updates (e.g. form-updater setting the field's value
      // after showing it). For group nodes, child.value is a live reference that
      // will be mutated when descendants change — cloning locks in this snapshot
      // so _init doesn't silently track _value and prevent dirty detection.
      const initialValue = cloneAny(child.value) as FormFieldValue

      // Always sync into _init, even if the key already exists. FormKit's
      // reset() sets _init at the root level from resetTo — which can include
      // values for hidden fields that have no child node. When such a field is
      // later shown, its child.value (hydrated from the parent's live _value)
      // may differ from what reset() stored in _init, causing a false dirty
      // state. Overwriting ensures _init reflects the child's actual settled
      // value, regardless of how the key got there.
      node.props._init[child.name] = initialValue

      // Sync into all ancestor _init objects.
      walkAncestors((target) => {
        target[child.name] = initialValue
      })

      reevaluateDirtyState()
    })
  })

  node.on('reset', () => {
    savedInitValues.clear()
  })
}

export default initializeFieldInitialValuesCleanupPlugin
