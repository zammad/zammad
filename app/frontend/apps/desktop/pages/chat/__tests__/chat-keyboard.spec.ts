// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { EnumChatSessionState } from '#shared/graphql/types.ts'

import {
  chatSession,
  currentAgent,
  mockAgentState,
  mockChatAgent,
  mockChatEnabled,
  mockChatPreferences,
  mockChatSessions,
  runningSession,
} from '#desktop/entities/chat/__tests__/mocks/chat-mocks.ts'

// The middle conversation has ended, so its window has no message input.
const sessions = [
  runningSession(1, currentAgent),
  chatSession(2, { state: EnumChatSessionState.Closed, user: currentAgent }),
  runningSession(3, currentAgent),
]

const openWindows = async (opened = sessions) => {
  mockAgentState({ runningSessions: opened })
  mockChatSessions(opened)

  const view = await visitView('/chat')

  const inputs = await view.findAllByLabelText('Message')

  return { view, inputs }
}

describe('Chat keyboard', () => {
  beforeEach(() => {
    mockChatAgent()
    mockChatEnabled()
    mockChatPreferences()
  })

  it('moves with Tab from message input to message input, around the ends, past a window without one', async () => {
    const { view, inputs } = await openWindows()

    expect(inputs).toHaveLength(2)
    expect(view.getByRole('region', { name: 'Support #2' })).toBeInTheDocument()

    await view.events.click(inputs[0])
    await view.events.tab()

    expect(inputs[1]).toHaveFocus()

    await view.events.tab()

    expect(inputs[0]).toHaveFocus()

    await view.events.tab({ shift: true })

    expect(inputs[1]).toHaveFocus()

    await view.events.tab({ shift: true })

    expect(inputs[0]).toHaveFocus()
  })

  it('leaves the loop on Escape: the window takes the focus, and Tab goes on in the page order through its controls, the send button before the input', async () => {
    const { view, inputs } = await openWindows()

    await view.events.type(inputs[0], 'Hello')
    await view.events.keyboard('{Escape}')

    expect(view.getByRole('region', { name: 'Support #1' })).toHaveFocus()

    // The title, which renames the chat, comes first.
    await view.events.tab()

    expect(document.activeElement).toContainElement(
      view.getByRole('heading', { level: 2, name: 'Support #1' }),
    )

    await view.events.tab()

    expect(view.getAllByRole('button', { name: 'Disconnect' })[0]).toHaveFocus()

    await view.events.tab()

    expect(view.getAllByRole('button', { name: 'Additional actions' })[0]).toHaveFocus()

    await view.events.tab()

    expect(document.activeElement).toHaveAttribute('href', 'https://example.com/pricing')

    await view.events.tab()

    expect(view.getAllByRole('button', { name: 'Send' })[0]).toHaveFocus()

    await view.events.tab()

    expect(inputs[0]).toHaveFocus()

    await view.events.tab()

    expect(inputs[1]).toHaveFocus()
  })

  it('leaves Tab and Escape alone with a single window, where Shift+Tab reaches the send button', async () => {
    const { view, inputs } = await openWindows([runningSession(1, currentAgent)])

    await view.events.type(inputs[0], 'Hello')
    await view.events.keyboard('{Escape}')

    expect(inputs[0]).toHaveFocus()

    await view.events.tab({ shift: true })

    expect(view.getByRole('button', { name: 'Send' })).toHaveFocus()

    await view.events.tab()

    expect(inputs[0]).toHaveFocus()
  })

  it('does not leave the input on the Escape that cancels an input method conversion', async () => {
    const { inputs } = await openWindows()

    inputs[0].focus()
    inputs[0].dispatchEvent(
      new KeyboardEvent('keydown', {
        key: 'Escape',
        bubbles: true,
        cancelable: true,
        isComposing: true,
      }),
    )

    await waitForNextTick()

    expect(inputs[0]).toHaveFocus()
  })
})
