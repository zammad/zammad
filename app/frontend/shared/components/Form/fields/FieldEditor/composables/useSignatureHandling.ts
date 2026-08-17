// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { DOMParser, Node as ProseMirrorNode } from '@tiptap/pm/model'

import type { PossibleSignature } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { htmlCleanup } from '#shared/utils/htmlCleanup.ts'
import testFlags from '#shared/utils/testFlags.ts'

import type { Editor } from '@tiptap/vue-3'
import type { ShallowRef } from 'vue'

const findTopLevelSignature = (editor: Editor): { pos: number; node: ProseMirrorNode } | null => {
  let existingSignature: { pos: number; node: ProseMirrorNode } | null = null

  editor.state.doc.descendants((node, pos, parent) => {
    if (node.type.name === 'signature' && parent?.type.name === 'doc') {
      existingSignature = { pos, node }
      return false
    }
  })

  return existingSignature
}

const tryToUpsertSignature = (
  editor: ShallowRef<Editor | undefined>,
  signature: PossibleSignature,
  options: { wasFocused: boolean; currentPosition: number },
) => {
  const { wasFocused, currentPosition } = options

  const existingSignature = editor.value ? findTopLevelSignature(editor.value) : null

  if (existingSignature && editor.value) {
    const signatureElement = htmlCleanup(
      `<div>${signature.renderedBody}</div>`,
      false,
      true,
    ) as Element

    const slice = DOMParser.fromSchema(editor.value.state.schema)
      .parseSlice(signatureElement)
      .toJSON()

    if (!slice) return false

    const { pos, node } = existingSignature

    editor.value.commands.insertContentAt(
      {
        from: pos,
        to: pos + node.nodeSize,
      },
      {
        type: 'signature',
        content: slice.content,
        attrs: { signatureId: signature.internalId },
      },
    )

    if (wasFocused) editor.value.commands.focus(signature.position ?? currentPosition)

    requestAnimationFrame(() => {
      testFlags.set('editor.signatureAdd')
    })

    return true
  }
}

export const useSignatureHandling = (editor: ShallowRef<Editor | undefined>) => {
  // insert signature before full article blockquote or at the end of the document
  const resolveSignaturePosition = (editor: Editor) => {
    let blockquotePosition: number | null = null
    editor.state.doc.descendants((node, pos) => {
      if (
        (node.type.name === 'paragraph' || node.type.name === 'blockquote') &&
        node.attrs['data-marker'] === 'signature-before'
      ) {
        blockquotePosition = pos
        return false
      }
    })
    if (blockquotePosition !== null) {
      return { position: 'before', from: blockquotePosition }
    }
    return { position: 'after', from: editor.state.doc.content.size || 0 }
  }

  const addSignature = (signature: PossibleSignature) => {
    if (!editor.value || editor.value.isDestroyed || !editor.value.isEditable) return

    const currentPosition = editor.value.state.selection.anchor
    const positionFromEnd = editor.value.state.doc.content.size - currentPosition
    const wasFocused = editor.value.isFocused

    // We try to upsert the signature if not it falls back to add it at the end off the doc
    const success = tryToUpsertSignature(editor, signature, { wasFocused, currentPosition })

    if (success) return

    // When no existing signature is in place we try determine the new position
    // don't use "chain()", because we change positions a lot
    // and chain doesn't know about it
    editor.value.commands.removeSignature()

    const { position, from } = resolveSignaturePosition(editor.value)

    editor.value.commands.addSignature({ ...signature, position, from })

    const getNewPosition = (editor: Editor) => {
      if (signature.position != null) {
        return signature.position
      }
      if (currentPosition < from) {
        return currentPosition
      }
      if (from === 0 && currentPosition <= 1) {
        return 1
      }
      return editor.state.doc.content.size - positionFromEnd
    }
    // Only restore focus if editor was previously focused
    if (wasFocused) editor.value.commands.focus(getNewPosition(editor.value))

    requestAnimationFrame(() => {
      testFlags.set('editor.signatureAdd')
    })
  }

  const removeSignature = () => {
    if (!editor.value || editor.value.isDestroyed || !editor.value.isEditable) return
    const currentPosition = editor.value.state.selection.anchor
    const wasFocused = editor.value.isFocused

    if (wasFocused) {
      editor.value.chain().removeSignature().focus(currentPosition).run()
    } else {
      editor.value.commands.removeSignature()
    }

    requestAnimationFrame(() => {
      testFlags.set('editor.removeSignature')
    })
  }

  // Reconcile the editor document against the given target signature, so the caller
  // never needs to know whether or when the signature was already applied.
  const reconcileSignature = (
    target: Pick<PossibleSignature, 'internalId' | 'renderedBody'> | null,
    options: { resetCursor?: boolean } = {},
  ) => {
    if (!editor.value || editor.value.isDestroyed || !editor.value.isEditable) return

    // Signature nodes are only part of the HTML extension set.
    if (!editor.value.schema.nodes.signature) return

    const existingSignature = findTopLevelSignature(editor.value)

    if (!target) {
      if (existingSignature) removeSignature()
      return
    }

    // The same signature is already present - leave it untouched, so restored drafts
    // and user edits inside the signature are preserved (#2319).
    if (
      existingSignature &&
      String(existingSignature.node.attrs.signatureId) === String(target.internalId)
    )
      return

    addSignature({
      renderedBody: target.renderedBody,
      internalId: target.internalId,
      position: options.resetCursor ? 1 : undefined,
    })

    // addSignature positions the cursor only for an already focused editor. Set the
    // selection also for an unfocused one, so a later focus (e.g. the queued reply
    // form focus) lands at the document start instead of inside the applied content.
    if (options.resetCursor && !editor.value.isFocused) {
      editor.value.commands.setTextSelection(1)
    }
  }

  return {
    addSignature,
    removeSignature,
    reconcileSignature,
  }
}
