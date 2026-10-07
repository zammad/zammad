// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, defineComponent, ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import type { MentionKnowledgeBaseRelatedAnswers } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import { useTicketEditForm } from '../useTicketEditForm.ts'

import type { ComputedRef } from 'vue'

type SchemaNode = { name?: string; props?: Record<string, unknown>; children?: unknown }

const findSchemaNode = (node: unknown, name: string): SchemaNode | undefined => {
  if (!node || typeof node !== 'object') return undefined
  if ((node as SchemaNode).name === name) return node as SchemaNode

  const { children } = node as SchemaNode
  if (!Array.isArray(children)) return undefined

  for (const child of children) {
    const found = findSchemaNode(child, name)
    if (found) return found
  }

  return undefined
}

const getBodyEditorMeta = (
  options?: Parameters<typeof useTicketEditForm>[2],
): Record<string, Record<string, unknown>> => {
  let articleSchema: unknown

  renderComponent(
    defineComponent({
      setup() {
        ;({ articleSchema } = useTicketEditForm(
          computed(() => createDummyTicket()),
          ref(),
          options,
        ))
        return () => null
      },
    }),
  )

  const { meta } = findSchemaNode(articleSchema, 'body')!.props!

  return (meta as ComputedRef<Record<string, Record<string, unknown>>>).value
}

describe('useTicketEditForm', () => {
  describe('knowledge base editor meta', () => {
    it('offers no related answers when none are handed in', () => {
      expect(getBodyEditorMeta().mentionKnowledgeBase).toEqual({
        attachmentsNodeName: 'attachments',
      })
    })

    it('hands the related answers to the knowledge base insertion', () => {
      const relatedAnswers = (): MentionKnowledgeBaseRelatedAnswers => ({
        linked: [],
        suggested: [],
      })

      expect(
        getBodyEditorMeta({ knowledgeBaseRelatedAnswers: relatedAnswers }).mentionKnowledgeBase,
      ).toEqual({
        attachmentsNodeName: 'attachments',
        relatedAnswers,
      })
    })
  })
})
