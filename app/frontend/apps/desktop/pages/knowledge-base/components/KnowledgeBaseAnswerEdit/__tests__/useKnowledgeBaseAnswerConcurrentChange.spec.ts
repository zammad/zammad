// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineComponent, nextTick, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { useKnowledgeBaseAnswerConcurrentChange } from '../useKnowledgeBaseAnswerConcurrentChange.ts'

import type { ComparableAnswer } from '../concurrentChange.ts'
import type { Ref } from 'vue'

const ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 42)
const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)

const answerWith = (overrides: Partial<ComparableAnswer> = {}) =>
  ({
    id: ANSWER_ID,
    editedAt: '2026-08-27T10:00:00Z',
    editedBy: null,
    attachments: [],
    category: { id: CATEGORY_ID },
    visibility: EnumKnowledgeBaseVisibility.Published,
    ...overrides,
  }) as ComparableAnswer

// The composable is driven by two refs and returns plain computeds, so a host that renders nothing
//   is enough - and keeps the baseline rule readable, which is what these examples are about.
const renderHost = (answer: Ref<ComparableAnswer | undefined>, answerConfirmed: Ref<boolean>) => {
  let api: ReturnType<typeof useKnowledgeBaseAnswerConcurrentChange>

  const Host = defineComponent({
    setup() {
      api = useKnowledgeBaseAnswerConcurrentChange({
        answer,
        answerConfirmed,
        localeCode: 'en-us',
      })

      return () => null
    },
  })

  renderComponent(Host, { router: true })

  return api!
}

describe('useKnowledgeBaseAnswerConcurrentChange', () => {
  // The app queries `cache-and-network`, so reopening this tab serves the entry it left behind
  //   before the server has said anything. A baseline taken from that would be contradicted by the
  //   very next result and reported as somebody else's change - one that happened before the tab
  //   was even opened.
  it('takes the baseline from the confirmed answer, not from a cache hit', async () => {
    const answer = ref<ComparableAnswer | undefined>(
      answerWith({ visibility: EnumKnowledgeBaseVisibility.Internal }),
    )
    const answerConfirmed = ref(false)

    const { foreignChange } = renderHost(answer, answerConfirmed)

    expect(foreignChange.value, 'nothing to compare against yet').toBeUndefined()

    // What the server actually holds: somebody published it while this tab was closed.
    answer.value = answerWith({ visibility: EnumKnowledgeBaseVisibility.Published })
    answerConfirmed.value = true
    await nextTick()

    expect(foreignChange.value).toBeUndefined()
  })

  // The other half: once the baseline is taken, a change on top of it is exactly what this reports.
  it('reports a change made after the baseline was taken', async () => {
    const answer = ref<ComparableAnswer | undefined>(answerWith())
    const answerConfirmed = ref(true)

    const { foreignChange } = renderHost(answer, answerConfirmed)

    expect(foreignChange.value).toBeUndefined()

    answer.value = answerWith({ visibility: EnumKnowledgeBaseVisibility.Internal })
    await nextTick()

    expect(foreignChange.value).toEqual({ editorName: undefined })
  })

  // A network result equal to what the cache held may not move `answer` at all, so the flag has to
  //   be watched in its own right - otherwise the baseline would never be taken and no concurrent
  //   change could ever be reported for this tab.
  it('takes the baseline when only the confirmation arrives', async () => {
    const answer = ref<ComparableAnswer | undefined>(answerWith())
    const answerConfirmed = ref(false)

    const { foreignChange, knownAttachments } = renderHost(answer, answerConfirmed)

    expect(knownAttachments.value).toBeUndefined()

    answerConfirmed.value = true
    await nextTick()

    expect(knownAttachments.value).toEqual([])
    expect(foreignChange.value).toBeUndefined()
  })
})
