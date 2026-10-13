// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, defineComponent, ref, shallowRef } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import type { FieldEditorContext } from '#shared/components/Form/fields/FieldEditor/types.ts'
import type { FormRef } from '#shared/components/Form/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

import { useKnowledgeBaseAnswerInsert } from '../useKnowledgeBaseAnswerInsert.ts'

const translationId = convertToGraphQLId('KnowledgeBase::Answer::Translation', 1)

const newTicketArticlePresent = ref<boolean | undefined>()
const isTicketEditable = ref(true)
const bodyContext = ref<Partial<FieldEditorContext> | undefined>()

const form = shallowRef({
  getNodeByName: (name: string) =>
    name === 'body' && bodyContext.value ? { context: bodyContext.value } : undefined,
} as unknown as FormRef)

let api: ReturnType<typeof useKnowledgeBaseAnswerInsert>

const renderInsert = () =>
  renderComponent(
    defineComponent({
      setup() {
        api = useKnowledgeBaseAnswerInsert()
        return () => null
      },
    }),
    {
      provide: [
        [
          TICKET_KEY,
          {
            form,
            isTicketEditable: computed(() => isTicketEditable.value),
            newTicketArticlePresent,
          },
        ],
      ],
    },
  )

describe('useKnowledgeBaseAnswerInsert', () => {
  beforeEach(() => {
    newTicketArticlePresent.value = undefined
    isTicketEditable.value = true
    bodyContext.value = { insertKnowledgeBaseAnswer: vi.fn() }
  })

  it('offers the insert only while an article is being written', () => {
    renderInsert()

    expect(api.canInsertAnswer.value).toBe(false)

    newTicketArticlePresent.value = true
    expect(api.canInsertAnswer.value).toBe(true)

    newTicketArticlePresent.value = false
    expect(api.canInsertAnswer.value).toBe(false)
  })

  it('does not offer the insert when the ticket is not editable', () => {
    newTicketArticlePresent.value = true
    isTicketEditable.value = false

    renderInsert()

    expect(api.canInsertAnswer.value).toBe(false)
  })

  it('hands the answer to the article body editor', () => {
    newTicketArticlePresent.value = true

    renderInsert()

    api.insertAnswer(translationId)

    expect(bodyContext.value?.insertKnowledgeBaseAnswer).toHaveBeenCalledWith(translationId)
  })

  it('does nothing when the body editor offers no insert', () => {
    newTicketArticlePresent.value = true
    bodyContext.value = {}

    renderInsert()

    expect(() => api.insertAnswer(translationId)).not.toThrow()
  })
})
