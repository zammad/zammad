// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import {
  EnumKnowledgeBaseAnswerScreen,
  EnumKnowledgeBaseAnswerScreenBehavior,
} from '#shared/graphql/types.ts'

import { waitForUserCurrentKnowledgeBaseAnswerScreenBehaviorMutationCalls } from '#desktop/entities/user/current/graphql/mutations/userCurrentKnowledgeBaseAnswerScreenBehavior.mocks.ts'

import KnowledgeBaseAnswerScreenBehavior from '../KnowledgeBaseAnswerScreenBehavior.vue'

const renderControl = (screen = EnumKnowledgeBaseAnswerScreen.Edit) =>
  renderComponent(KnowledgeBaseAnswerScreenBehavior, { props: { screen }, router: true })

describe('KnowledgeBaseAnswerScreenBehavior', () => {
  // No admin default exists for the knowledge base, unlike the ticket control's
  //   `ticket_secondary_action` - so an untouched user has to land on "stay on tab" in code.
  it('defaults to staying on the tab', async () => {
    mockUserCurrent({ preferences: { knowledgeBaseAnswerSecondaryAction: undefined } })

    const view = renderControl()

    await view.events.click(view.getByRole('button', { name: 'Stay on tab' }))

    const menu = await view.findByRole('menu')

    expect(within(menu).getByRole('checkbox', { checked: true })).toHaveTextContent('Stay on tab')
  })

  // The ticket-only options must not leak in here, and neither must the create screen's own.
  it('offers staying and the two destinations, and nothing else', async () => {
    mockUserCurrent({
      preferences: {
        knowledgeBaseAnswerSecondaryAction: EnumKnowledgeBaseAnswerScreenBehavior.StayOnTab,
      },
    })

    const view = renderControl()

    await view.events.click(view.getByRole('button', { name: 'Stay on tab' }))

    const menu = await view.findByRole('menu')

    expect(within(menu).getAllByRole('checkbox')).toHaveLength(3)
    expect(menu).toHaveTextContent('Close tab and open the answer')
    expect(menu).toHaveTextContent('Close tab and open the category')
    expect(menu).not.toHaveTextContent('Close tab on ticket close')

    // There is no second answer to add from an edit tab.
    expect(menu).not.toHaveTextContent('add another answer')
  })

  it('shows the stored preference', async () => {
    mockUserCurrent({
      preferences: {
        knowledgeBaseAnswerSecondaryAction:
          EnumKnowledgeBaseAnswerScreenBehavior.CloseTabAndOpenCategory,
      },
    })

    const view = renderControl()

    await view.events.click(view.getByRole('button', { name: 'Close tab and open the category' }))

    const menu = await view.findByRole('menu')

    expect(within(menu).getByRole('checkbox', { checked: true })).toHaveTextContent(
      'Close tab and open the category',
    )
  })

  it('stores a picked behavior', async () => {
    mockUserCurrent({
      preferences: {
        knowledgeBaseAnswerSecondaryAction: EnumKnowledgeBaseAnswerScreenBehavior.StayOnTab,
      },
    })

    const view = renderControl()

    await view.events.click(view.getByRole('button', { name: 'Stay on tab' }))

    const menu = await view.findByRole('menu')

    await view.events.click(
      within(menu).getByRole('checkbox', { name: /Close tab and open the answer/ }),
    )

    const calls = await waitForUserCurrentKnowledgeBaseAnswerScreenBehaviorMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      screen: EnumKnowledgeBaseAnswerScreen.Edit,
      behavior: EnumKnowledgeBaseAnswerScreenBehavior.CloseTabAndOpenAnswer,
    })
  })

  // The create screen keeps a preference of its own, and one option of its own: its tab cannot hold
  //   the created answer, so instead of staying it offers closing and opening a fresh form.
  describe('on the create screen', () => {
    it('reads and writes its own preference', async () => {
      mockUserCurrent({
        preferences: {
          knowledgeBaseAnswerCreateSecondaryAction:
            EnumKnowledgeBaseAnswerScreenBehavior.CloseTabAndOpenCategory,
          // The edit choice, which must not be what this control shows.
          knowledgeBaseAnswerSecondaryAction: EnumKnowledgeBaseAnswerScreenBehavior.StayOnTab,
        },
      })

      const view = renderControl(EnumKnowledgeBaseAnswerScreen.Create)

      await view.events.click(view.getByRole('button', { name: 'Close tab and open the category' }))

      const menu = await view.findByRole('menu')

      await view.events.click(
        within(menu).getByRole('checkbox', { name: /Close tab and add another answer/ }),
      )

      const calls = await waitForUserCurrentKnowledgeBaseAnswerScreenBehaviorMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        screen: EnumKnowledgeBaseAnswerScreen.Create,
        behavior: EnumKnowledgeBaseAnswerScreenBehavior.CloseTabAndAddAnother,
      })
    })

    // Adding another answer instead of staying, and nothing that needs a tab which outlives the
    //   save. Its default is what the view did before it had a choice at all.
    it('offers adding another answer, and not staying', async () => {
      mockUserCurrent({ preferences: {} })

      const view = renderControl(EnumKnowledgeBaseAnswerScreen.Create)

      await view.events.click(view.getByRole('button', { name: 'Close tab and open the answer' }))

      const menu = await view.findByRole('menu')

      expect(within(menu).getAllByRole('checkbox')).toHaveLength(3)
      expect(menu).toHaveTextContent('Close tab and add another answer')
      expect(menu).not.toHaveTextContent('Stay on tab')
    })

    // The edit screen's own value: it cannot be picked here, so a leftover in the preferences reads
    //   as unset rather than as a behavior this control cannot even show.
    it('shows its default for a stored behavior it does not offer', async () => {
      mockUserCurrent({
        preferences: {
          knowledgeBaseAnswerCreateSecondaryAction: EnumKnowledgeBaseAnswerScreenBehavior.StayOnTab,
        },
      })

      const view = renderControl(EnumKnowledgeBaseAnswerScreen.Create)

      expect(
        view.getByRole('button', { name: 'Close tab and open the answer' }),
      ).toBeInTheDocument()
    })
  })
})
