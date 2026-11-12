// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { GraphQLError } from 'graphql'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { nullableMock, waitForNextTick, waitUntil } from '#tests/support/utils.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { imageViewerOptions } from '#shared/composables/useImageViewer.ts'
import {
  EnumChatSessionState,
  type ChatAgentStateUpdatesSubscription,
  type ChatSessionUpdatesSubscription,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import emitter from '#shared/utils/emitter.ts'

import {
  agentState,
  chatMessage,
  chatSession,
  colleague,
  currentAgent,
  mockAgentState,
  mockChatAgent,
  mockChatEnabled,
  mockChatPreferences,
  mockChatSession,
  runningSession,
  salesTopic,
  supportTopic,
} from '#desktop/entities/chat/__tests__/mocks/chat-mocks.ts'
import { ChatSessionEndDocument } from '#desktop/entities/chat/graphql/mutations/chatSessionEnd.api.ts'
import {
  mockChatSessionEndMutation,
  mockChatSessionEndMutationError,
  waitForChatSessionEndMutationCalls,
} from '#desktop/entities/chat/graphql/mutations/chatSessionEnd.mocks.ts'
import {
  mockChatSessionMessageAddMutation,
  waitForChatSessionMessageAddMutationCalls,
} from '#desktop/entities/chat/graphql/mutations/chatSessionMessageAdd.mocks.ts'
import { ChatSessionRenameDocument } from '#desktop/entities/chat/graphql/mutations/chatSessionRename.api.ts'
import {
  mockChatSessionRenameMutation,
  waitForChatSessionRenameMutationCalls,
} from '#desktop/entities/chat/graphql/mutations/chatSessionRename.mocks.ts'
import { ChatSessionTypingDocument } from '#desktop/entities/chat/graphql/mutations/chatSessionTyping.api.ts'
import { mockChatSessionTypingMutation } from '#desktop/entities/chat/graphql/mutations/chatSessionTyping.mocks.ts'
import { waitForChatAgentStateQueryCalls } from '#desktop/entities/chat/graphql/queries/chatAgentState.mocks.ts'
import { mockChatSessionQuery } from '#desktop/entities/chat/graphql/queries/chatSession.mocks.ts'
import { getChatAgentStateUpdatesSubscriptionHandler } from '#desktop/entities/chat/graphql/subscriptions/chatAgentStateUpdates.mocks.ts'
import { ChatSessionUpdatesDocument } from '#desktop/entities/chat/graphql/subscriptions/chatSessionUpdates.api.ts'
import { getChatSessionUpdatesSubscriptionHandler } from '#desktop/entities/chat/graphql/subscriptions/chatSessionUpdates.mocks.ts'
import { useChatUnreadMessagesStore } from '#desktop/entities/chat/stores/chatUnreadMessages.ts'

// The window reports to the notification, which plays a sound jsdom cannot.
class AudioStub {
  currentTime = 0

  play = () => Promise.resolve()
}

const session = runningSession(1, currentAgent)

const customerMessage = chatMessage(1, '<div>Hello</div>', '2026-11-03T11:00:00Z')

const pushUpdate = async (
  update: Partial<ChatSessionUpdatesSubscription['chatSessionUpdates']> = {},
) => {
  await getChatSessionUpdatesSubscriptionHandler().trigger(
    nullableMock<ChatSessionUpdatesSubscription>({
      chatSessionUpdates: {
        __typename: 'ChatSessionUpdatesPayload',
        message: null,
        typing: null,
        notice: null,
        leftBy: null,
        closedBy: null,
        ...update,
      },
    }),
  )
  await waitForNextTick()
}

// What the state tells about the running sessions, e.g. after an accept or a transfer.
const pushRunningSessions = async (sessions: ReturnType<typeof chatSession>[]) => {
  await waitForChatAgentStateQueryCalls()

  await getChatAgentStateUpdatesSubscriptionHandler().trigger(
    nullableMock<ChatAgentStateUpdatesSubscription>({
      chatAgentStateUpdates: {
        __typename: 'ChatAgentStateUpdatesPayload',
        agentState: agentState({ runningSessions: sessions }),
      },
    }),
  )
  await waitForNextTick()
}

// The session went elsewhere, e.g. a transfer in another tab or the old interface.
const pushStateWithoutSession = () => pushRunningSessions([])

// The server refuses a subscription to a session that is back in a queue or went elsewhere, and
//   ends it with that: the listener for new messages shares the stream, which would stay open here.
const refuseSubscription = async () => {
  const handler = getChatSessionUpdatesSubscriptionHandler()

  await handler.triggerErrors([
    new GraphQLError('not allowed to Chat::SessionPolicy#subscribe? this Chat::Session', {
      extensions: { type: GraphQLErrorTypes.Forbidden },
    }),
  ])
  handler.complete()
  await waitForNextTick()
}

const openWindow = async (messages: ReturnType<typeof chatMessage>[] = []) => {
  mockAgentState({ runningSessions: [session] })
  mockChatSession(session, messages)

  const view = await visitView('/chat')

  await view.findByRole('region', { name: 'Support #1' })

  return view
}

// A session found through search opens by its route, whoever runs it.
const openFoundWindow = async (
  found: ReturnType<typeof chatSession>,
  messages: ReturnType<typeof chatMessage>[] = [],
) => {
  mockAgentState({ runningSessions: [] })
  mockChatSession(found, messages)

  const view = await visitView(`/chat/session/${found.internalId}`)

  await view.findByRole('region', { name: 'Support #5' })

  return view
}

describe('Chat window', () => {
  beforeEach(() => {
    vi.stubGlobal('Audio', AudioStub)
    mockChatAgent()
    mockChatEnabled()
    mockChatPreferences()
    mockChatSessionTypingMutation({ chatSessionTyping: { success: true, errors: null } })

    // Notices outlive an example, so one example's would show up in the next.
    useNotifications().clearAllNotifications()
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    vi.useRealTimers()
  })

  it('shows the history and the connection line of a running conversation', async () => {
    const view = await openWindow([
      customerMessage,
      chatMessage(2, '<div>How can I help?</div>', '2026-11-03T11:00:30Z', currentAgent),
    ])

    expect(view.getByRole('img', { name: 'Online' })).toBeInTheDocument()
    expect(await view.findByText('Hello')).toBeInTheDocument()
    expect(view.getByText('How can I help?')).toBeInTheDocument()
    expect(view.getByText('Message from the customer')).toBeInTheDocument()
    expect(view.getByText('Message from Chat Agent')).toBeInTheDocument()
    expect(view.getByText('Germany, Berlin')).toBeInTheDocument()
    // The page heads the history, like in the old interface.
    const log = within(view.getByRole('log'))

    expect(log.getByRole('note')).toHaveTextContent('Started from https://example.com/pricing')

    const startPage = log.getByRole('link', { name: 'https://example.com/pricing' })

    expect(startPage).toHaveAttribute('href', 'https://example.com/pricing')
    expect(startPage).toHaveAttribute('target', '_blank')
    expect(startPage).toHaveAttribute('rel', 'noopener noreferrer')
  })

  it('names a start page that is no web address without linking it', async () => {
    const unsafe = { ...session, url: 'javascript:alert(1)' }

    mockAgentState({ runningSessions: [unsafe] })
    mockChatSession(unsafe, [])

    const view = await visitView('/chat')

    await view.findByRole('region', { name: 'Support #1' })

    const log = within(view.getByRole('log'))

    expect(log.getByRole('note')).toHaveTextContent('Started from javascript:alert(1)')
    expect(log.queryByRole('link')).not.toBeInTheDocument()
  })

  it('opens a link to Zammad in a new window of this app, and keeps the chat open', async () => {
    const open = vi.fn()
    vi.stubGlobal('open', open)

    // As the server stores a link to Zammad pasted as a link: without a target, unlike a typed address.
    const view = await openWindow([
      chatMessage(
        1,
        '<div><a href="http://localhost:3000/#ticket/zoom/1" rel="nofollow noreferrer noopener" title="http://localhost:3000/#ticket/zoom/1">Ticket</a></div>',
        '2026-11-03T11:00:00Z',
      ),
    ])

    await view.events.click(await view.findByRole('link', { name: 'Ticket' }))

    expect(open).toHaveBeenCalledWith('/desktop/ticket/zoom/1', '_blank')
    expect(view.getByRole('region', { name: 'Support #1' })).toBeInTheDocument()
  })

  it('names the state of the conversation in a tooltip instead of a visible label', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true })

    const view = await openWindow()

    expect(view.queryByText('Online')).not.toBeInTheDocument()

    await view.events.hover(view.getByRole('img', { name: 'Online' }))
    vi.advanceTimersByTime(1000)

    expect(view.getByRole('tooltip', { hidden: true })).toHaveTextContent('Online')
  })

  describe('images', () => {
    const PNG = 'data:image/png;base64,iVBORw0KGgo='
    // The widget sends a pasted image as a JPEG, whatever it was.
    const JPEG = 'data:image/jpeg;base64,/9j/4AAQSkZJRg=='

    beforeEach(() => {
      // The image viewer only shows what the system shows inline.
      mockApplicationConfig({
        'active_storage.content_types_allowed_inline': ['image/png', 'image/jpeg'],
      })
    })

    afterEach(() => {
      imageViewerOptions.value = { visible: false, index: 0, images: [] }
    })

    it('opens an image of the customer in the image viewer on click', async () => {
      const view = await openWindow([
        chatMessage(
          1,
          `<div>Look:</div><img style="width: 100%; max-width: 230px;" src="${JPEG}">`,
          '2026-11-03T11:00:00Z',
        ),
      ])

      await view.findByText('Look:')

      const image = view.getByTestId('chat-message').querySelector('img')!

      expect(image).toHaveAttribute('src', JPEG)
      // At the width the widget gave it, not stretched to the bubble.
      expect(image).toHaveStyle({ width: '100%', maxWidth: '230px' })

      await view.events.click(image)

      expect(imageViewerOptions.value).toMatchObject({
        visible: true,
        index: 0,
        images: [{ src: JPEG }],
      })
    })

    it('opens a JPEG of the customer where the system shows no PNG inline', async () => {
      mockApplicationConfig({ 'active_storage.content_types_allowed_inline': ['image/jpeg'] })

      const view = await openWindow([
        chatMessage(1, `<div>Look:</div><img src="${JPEG}">`, '2026-11-03T11:00:00Z'),
      ])

      await view.findByText('Look:')

      await view.events.click(view.getByTestId('chat-message').querySelector('img')!)

      expect(imageViewerOptions.value).toMatchObject({ visible: true, images: [{ src: JPEG }] })
    })

    it('opens an image from the keyboard, with Enter and with Space', async () => {
      const view = await openWindow([
        chatMessage(1, `<div>Look:</div><img src="${JPEG}">`, '2026-11-03T11:00:00Z'),
      ])

      await view.findByText('Look:')

      const image = view.getByRole('button', { name: 'Open image preview' })

      expect(image).toHaveAttribute('tabindex', '0')

      image.focus()

      expect(image).toHaveFocus()

      await view.events.keyboard('{Enter}')

      expect(imageViewerOptions.value).toMatchObject({ visible: true, images: [{ src: JPEG }] })

      imageViewerOptions.value = { visible: false, index: 0, images: [] }

      await view.events.keyboard(' ')

      expect(imageViewerOptions.value).toMatchObject({ visible: true, images: [{ src: JPEG }] })
    })

    it('opens the clicked one of several images, also in a message of the agent', async () => {
      const view = await openWindow([
        chatMessage(
          1,
          `<div>Both:</div><img style="max-width: 100%;" src="${PNG}"><img style="max-width: 100%;" src="${JPEG}">`,
          '2026-11-03T11:00:00Z',
          currentAgent,
        ),
      ])

      await view.findByText('Both:')

      const images = view.getByTestId('chat-message').querySelectorAll('img')

      await view.events.click(images[1])

      expect(imageViewerOptions.value).toMatchObject({
        visible: true,
        index: 1,
        images: [{ src: PNG }, { src: JPEG }],
      })
    })
  })

  it('shows a time only where more than two minutes passed since the message before', async () => {
    const view = await openWindow([
      customerMessage,
      chatMessage(2, '<div>One</div>', '2026-11-03T11:01:00Z', currentAgent),
      chatMessage(3, '<div>Two</div>', '2026-11-03T11:05:00Z'),
    ])

    await view.findByText('Two')

    // The one of the connection line, and one each for the first message and the one after the pause.
    expect(view.container.querySelectorAll('time')).toHaveLength(3)
  })

  it('moves messages one after another from the same side closer together', async () => {
    const view = await openWindow([
      customerMessage,
      chatMessage(2, '<div>Anybody there?</div>', '2026-11-03T11:00:10Z'),
      chatMessage(3, '<div>How can I help?</div>', '2026-11-03T11:00:20Z', currentAgent),
      chatMessage(4, '<div>Sorry for the wait.</div>', '2026-11-03T11:04:00Z', currentAgent),
    ])

    await view.findByText('Sorry for the wait.')

    const [first, followUp, otherSide, afterPause] = view
      .getAllByTestId('chat-message')
      .map((bubble) => bubble.parentElement?.parentElement)

    expect(first).not.toHaveClass('-mt-4')
    expect(followUp).toHaveClass('-mt-4')
    expect(otherSide).not.toHaveClass('-mt-4')
    expect(afterPause).not.toHaveClass('-mt-4')
  })

  describe('live updates', () => {
    it('adds a message of the customer once, however often it is pushed', async () => {
      const view = await openWindow()

      const message = chatMessage(5, '<div>Anybody there?</div>', '2026-11-03T11:10:00Z')

      await pushUpdate({ message })
      await pushUpdate({ message })

      expect(await view.findAllByText('Anybody there?')).toHaveLength(1)
    })

    it('shows what the customer wrote while the connection was down once it is back, where it was said', async () => {
      const answer = chatMessage(3, '<div>Answer</div>', '2026-11-03T11:00:50Z', currentAgent)

      mockChatSessionMessageAddMutation({
        chatSessionMessageAdd: { message: answer, errors: null },
      })

      const view = await openWindow([customerMessage])

      expect(await view.findByText('Hello')).toBeInTheDocument()

      // The mutation goes over HTTP, so the answer arrives while the subscription is down.
      await view.events.type(await view.findByLabelText('Message'), 'Answer{Enter}')
      await view.findByText('Answer')

      mockChatSession(session, [
        customerMessage,
        chatMessage(2, '<div>Still there?</div>', '2026-11-03T11:00:40Z'),
        answer,
      ])

      emitter.emit('reconnected')

      expect(await view.findByText('Still there?')).toBeInTheDocument()
      expect(view.getAllByTestId('chat-message').map((bubble) => bubble.textContent)).toEqual([
        'Hello',
        'Still there?',
        'Answer',
      ])
    })

    it('counts what the customer wrote while the connection was down as unread', async () => {
      const view = await openWindow([customerMessage])

      expect(await view.findByText('Hello')).toBeInTheDocument()

      mockChatSession(session, [
        customerMessage,
        chatMessage(2, '<div>Still there?</div>', '2026-11-03T11:00:40Z'),
      ])

      emitter.emit('reconnected')

      expect(await view.findByText('Still there?')).toBeInTheDocument()

      // The subscription did not carry it, so the window tells the notification about it.
      expect(useChatUnreadMessagesStore().total).toBe(1)
      expect(view.getAllByText('Hello')).toHaveLength(1)
    })

    it('shows that the customer is typing, and stops after two seconds', async () => {
      vi.useFakeTimers({ shouldAdvanceTime: true })

      const view = await openWindow()

      await pushUpdate({ typing: true })

      expect(
        await view.findByRole('status', { name: 'The customer is typing' }),
      ).toBeInTheDocument()

      await vi.advanceTimersByTimeAsync(2100)

      expect(view.queryByRole('status', { name: 'The customer is typing' })).not.toBeInTheDocument()
    })

    it('moves the typing closer to a message of the customer only', async () => {
      const view = await openWindow([customerMessage])

      await pushUpdate({ typing: true })

      expect(await view.findByRole('status', { name: 'The customer is typing' })).toHaveClass(
        '-mt-4',
      )

      await pushUpdate({
        message: chatMessage(2, '<div>How can I help?</div>', '2026-11-03T11:00:30Z', currentAgent),
      })
      await pushUpdate({ typing: true })

      expect(await view.findByRole('status', { name: 'The customer is typing' })).not.toHaveClass(
        '-mt-4',
      )
    })

    it('shows what the customer does as a notice', async () => {
      const view = await openWindow()

      await pushUpdate({ notice: 'The customer moved to https://example.com/plans' })

      expect(
        await view.findByText('The customer moved to https://example.com/plans'),
      ).toHaveAttribute('role', 'note')
    })

    it('links the page the customer moved to in a new tab, and nothing but a web address', async () => {
      const view = await openWindow()

      await pushUpdate({ notice: 'https://example.com/plans' })

      const link = await view.findByRole('link', { name: 'https://example.com/plans' })

      expect(link).toHaveAttribute('href', 'https://example.com/plans')
      expect(link).toHaveAttribute('target', '_blank')
      expect(link).toHaveAttribute('rel', 'noopener noreferrer')

      await pushUpdate({ notice: 'javascript:alert(1)' })

      expect(await view.findByText('javascript:alert(1)')).toHaveAttribute('role', 'note')
      expect(view.queryByRole('link', { name: 'javascript:alert(1)' })).not.toBeInTheDocument()
    })

    describe('following the newest entry', () => {
      // jsdom lays nothing out: the sizes make the thread longer than its box.
      const scrollThreadTo = (view: Awaited<ReturnType<typeof openWindow>>, scrollTop: number) => {
        const thread = view.getByRole('log')

        Object.defineProperties(thread, {
          scrollHeight: { value: 1000 },
          clientHeight: { value: 300 },
          scrollTop: { value: scrollTop, writable: true },
        })
        thread.dispatchEvent(new Event('scroll'))
        vi.mocked(thread.scrollTo).mockClear()

        return thread
      }

      const laterMessage = chatMessage(5, '<div>Anybody there?</div>', '2026-11-03T11:10:00Z')

      it('starts at the newest entry when the conversation opens with its history', async () => {
        const view = await openWindow([customerMessage, laterMessage])

        await view.findByText('Anybody there?')

        const thread = view.getByRole('log')

        await waitFor(() =>
          expect(thread.scrollTo).toHaveBeenCalledWith({ top: thread.scrollHeight }),
        )
      })

      it('scrolls to a new message while the agent reads the newest one', async () => {
        const view = await openWindow([customerMessage])

        await view.findByText('Hello')

        const thread = scrollThreadTo(view, 700)

        await pushUpdate({ message: laterMessage })

        await waitFor(() => expect(thread.scrollTo).toHaveBeenCalledWith({ top: 1000 }))
      })

      it('leaves an agent who scrolled up where they are', async () => {
        const view = await openWindow([customerMessage])

        await view.findByText('Hello')

        const thread = scrollThreadTo(view, 0)

        await pushUpdate({ message: laterMessage })
        await pushUpdate({ typing: true })

        expect(await view.findByText('Anybody there?')).toBeInTheDocument()
        expect(thread.scrollTo).not.toHaveBeenCalled()
      })

      describe('the button to what arrived below', () => {
        const lastMessage = chatMessage(6, '<div>Hello?</div>', '2026-11-03T11:11:00Z')

        const scrollButton = (view: Awaited<ReturnType<typeof openWindow>>) =>
          view.queryByRole('button', { name: /^Scroll to (end|unread item)$/ })

        const unreadBadge = (view: Awaited<ReturnType<typeof openWindow>>) =>
          view.queryByRole('status', { name: 'Unread messages count' })

        const openScrolledUp = async (messages = [customerMessage]) => {
          const view = await openWindow(messages)

          await view.findByText('Hello')

          return { view, thread: scrollThreadTo(view, 0) }
        }

        // jsdom lays nothing out: the divider sits that far below the top of the thread, which the
        //   thread measures on the next scroll.
        const placeDivider = (
          view: Awaited<ReturnType<typeof openWindow>>,
          thread: HTMLElement,
          offset: number,
        ) => {
          const row = view.getByText('Unread messages').parentElement!

          vi.spyOn(thread, 'getBoundingClientRect').mockReturnValue({ top: 100 } as DOMRect)
          vi.spyOn(row, 'getBoundingClientRect').mockReturnValue({ top: 100 + offset } as DOMRect)

          thread.dispatchEvent(new Event('scroll'))
        }

        it('shows the unread count on it after a message of the customer while the agent reads back', async () => {
          const { view, thread } = await openScrolledUp()

          await pushUpdate({ message: laterMessage })

          placeDivider(view, thread, 300)

          expect(
            await view.findByRole('button', { name: 'Scroll to unread item' }),
          ).toBeInTheDocument()
          expect(unreadBadge(view)).toHaveTextContent('1')
        })

        it('shows none for a message the agent sees arrive at the end', async () => {
          const view = await openWindow([customerMessage])

          await view.findByText('Hello')

          scrollThreadTo(view, 700)

          await pushUpdate({ message: laterMessage })

          expect(await view.findByText('Anybody there?')).toBeInTheDocument()
          expect(scrollButton(view)).not.toBeInTheDocument()
        })

        it("shows none for typing, a notice or the agent's own message", async () => {
          const { view } = await openScrolledUp()

          await pushUpdate({ typing: true })
          await pushUpdate({ notice: 'https://example.com/plans' })
          await pushUpdate({
            message: chatMessage(8, '<div>One moment.</div>', '2026-11-03T11:12:00Z', currentAgent),
          })

          expect(await view.findByText('One moment.')).toBeInTheDocument()
          expect(scrollButton(view)).not.toBeInTheDocument()
        })

        it('goes to where the unread messages begin, leaves them unread, and then on to the end', async () => {
          const { view, thread } = await openScrolledUp()

          await pushUpdate({ message: laterMessage })
          await pushUpdate({ message: lastMessage })

          placeDivider(view, thread, 300)

          await view.events.click(
            await view.findByRole('button', { name: 'Scroll to unread item' }),
          )

          expect(thread.scrollTo).toHaveBeenCalledWith({ top: 300 })
          expect(view.getByText('Unread messages')).toBeInTheDocument()
          expect(useChatUnreadMessagesStore().total).toBe(2)

          // Where the jump took the agent.
          placeDivider(view, thread, 0)

          const button = await view.findByRole('button', { name: 'Scroll to end' })

          expect(unreadBadge(view)).not.toBeInTheDocument()

          await view.events.click(button)

          expect(thread.scrollTo).toHaveBeenLastCalledWith({ top: 1000 })
        })

        it('goes to the end once the agent scrolled past where the unread messages begin', async () => {
          const { view, thread } = await openScrolledUp()

          await pushUpdate({ message: laterMessage })

          placeDivider(view, thread, -200)

          await view.events.click(await view.findByRole('button', { name: 'Scroll to end' }))

          expect(unreadBadge(view)).not.toBeInTheDocument()
          expect(thread.scrollTo).toHaveBeenCalledWith({ top: 1000 })
        })

        it('goes to where the unread messages begin from the keyboard as well', async () => {
          const { view, thread } = await openScrolledUp()

          await pushUpdate({ message: laterMessage })

          placeDivider(view, thread, 300)

          ;(await view.findByRole('button', { name: 'Scroll to unread item' })).focus()

          await view.events.keyboard('{Enter}')

          expect(thread.scrollTo).toHaveBeenCalledWith({ top: 300 })
          expect(view.getByText('Unread messages')).toBeInTheDocument()
        })

        it('goes to the end without a number in the window whose message input the agent is in', async () => {
          const view = await openWindow([customerMessage])

          await view.events.click(await view.findByLabelText('Message'))

          const thread = scrollThreadTo(view, 0)

          await pushUpdate({ message: laterMessage })

          const button = await view.findByRole('button', { name: 'Scroll to end' })

          expect(unreadBadge(view)).not.toBeInTheDocument()

          await view.events.click(button)

          await waitFor(() => expect(thread.scrollTo).toHaveBeenCalledWith({ top: 1000 }))
        })

        // Gone with the focus, the button would leave a keyboard agent at the start of the page.
        it('keeps the focus in the window when the button it had goes away', async () => {
          const { view, thread } = await openScrolledUp()

          await pushUpdate({ message: laterMessage })

          await view.events.click(await view.findByRole('button', { name: 'Scroll to end' }))

          thread.scrollTop = 700
          thread.dispatchEvent(new Event('scroll'))

          await waitFor(() => expect(scrollButton(view)).not.toBeInTheDocument())
          expect(view.getByRole('region', { name: 'Support #1' })).toHaveFocus()
        })

        it('goes away once the agent is at the end', async () => {
          const { view, thread } = await openScrolledUp()

          await pushUpdate({ message: laterMessage })

          expect(scrollButton(view)).toBeInTheDocument()

          thread.scrollTop = 700
          thread.dispatchEvent(new Event('scroll'))

          await waitFor(() => expect(scrollButton(view)).not.toBeInTheDocument())
        })

        it("shows no number in a colleague's conversation the agent only reads", async () => {
          const view = await openFoundWindow(runningSession(5, colleague), [customerMessage])

          await view.findByText('This conversation is handled by Other Agent.')

          scrollThreadTo(view, 0)

          await pushUpdate({ message: laterMessage })

          expect(await view.findByRole('button', { name: 'Scroll to end' })).toBeInTheDocument()
          expect(unreadBadge(view)).not.toBeInTheDocument()
        })
      })
    })
  })

  describe('writing', () => {
    // The editor of the composer is a textarea in this suite (see vitest.setup.ts); the HTML it
    //   produces is covered by ChatComposer.browser.spec.ts.
    it('sends what the composer holds and clears the field', async () => {
      mockChatSessionMessageAddMutation({
        chatSessionMessageAdd: {
          message: chatMessage(7, 'Hello there', '2026-11-03T11:20:00Z', currentAgent),
          errors: null,
        },
      })

      const view = await openWindow()

      const field = await view.findByLabelText('Message')

      await view.events.type(field, 'Hello there')
      await view.events.click(view.getByRole('button', { name: 'Send' }))

      const calls = await waitForChatSessionMessageAddMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        sessionId: session.id,
        content: 'Hello there',
      })

      expect(await view.findByText('Hello there')).toBeInTheDocument()
      await waitUntil(() => (field as HTMLTextAreaElement).value === '')
    })

    it('sends on Enter and keeps a new line for Shift+Enter', async () => {
      mockChatSessionMessageAddMutation({
        chatSessionMessageAdd: {
          message: chatMessage(7, 'One<br>Two', '2026-11-03T11:20:00Z', currentAgent),
          errors: null,
        },
      })

      const view = await openWindow()

      const field = await view.findByLabelText('Message')

      await view.events.type(field, 'One{Shift>}{Enter}{/Shift}Two')

      expect(getGraphQLMockCalls(ChatSessionTypingDocument).length).toBeGreaterThan(0)
      expect(field).toHaveValue('One\nTwo')

      await view.events.type(field, '{Enter}')

      const calls = await waitForChatSessionMessageAddMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        sessionId: session.id,
        content: 'One\nTwo',
      })
    })

    it('cannot send nothing', async () => {
      const view = await openWindow()

      await view.findByLabelText('Message')

      expect(view.getByRole('button', { name: 'Send' })).toBeDisabled()

      await view.events.type(view.getByLabelText('Message'), '   ')

      expect(view.getByRole('button', { name: 'Send' })).toBeDisabled()
    })

    it('tells the customer once per burst of typing', async () => {
      const view = await openWindow()

      await view.events.type(await view.findByLabelText('Message'), 'abcdef')

      expect(getGraphQLMockCalls(ChatSessionTypingDocument)).toHaveLength(1)
      expect(getGraphQLMockCalls(ChatSessionTypingDocument)[0].variables).toEqual({
        sessionId: session.id,
      })
    })

    it('does not tell the customer about typing after the message was sent', async () => {
      vi.useFakeTimers({ shouldAdvanceTime: true })

      mockChatSessionMessageAddMutation({
        chatSessionMessageAdd: {
          message: chatMessage(7, '<div>abcdef</div>', '2026-11-03T11:20:00Z', currentAgent),
          errors: null,
        },
      })

      const view = await openWindow()

      await view.events.type(await view.findByLabelText('Message'), 'abcdef{Enter}')
      await waitForChatSessionMessageAddMutationCalls()

      await vi.advanceTimersByTimeAsync(2100)

      expect(getGraphQLMockCalls(ChatSessionTypingDocument)).toHaveLength(1)
    })
  })

  describe('when the conversation is over', () => {
    it('shows that the customer left, blocks the composer and lets the agent close the window', async () => {
      const view = await openWindow()

      await pushUpdate({ leftBy: 'Anonymous' })

      expect(await view.findByRole('img', { name: 'Disconnected' })).toBeInTheDocument()
      expect(view.getByText('Anonymous left the conversation.')).toBeInTheDocument()
      expect(view.queryByLabelText('Message')).not.toBeInTheDocument()
      expect(view.queryByRole('button', { name: 'Disconnect' })).not.toBeInTheDocument()

      const closeButton = view.getByRole('button', { name: 'Close window' })

      expect(closeButton).toHaveTextContent('Close')

      await view.events.click(closeButton)

      expect(view.queryByRole('region', { name: 'Support #1' })).not.toBeInTheDocument()
    })

    it('shows that the customer closed it', async () => {
      const view = await openWindow()

      await pushUpdate({ closedBy: 'Anonymous' })

      expect(await view.findByRole('img', { name: 'Closed' })).toBeInTheDocument()
      expect(view.getByText('Anonymous closed the conversation.')).toBeInTheDocument()
      expect(view.queryByLabelText('Message')).not.toBeInTheDocument()

      // In the thread after the last message, below when it ended; the footer keeps the button.
      const note = view.getByText('Anonymous closed the conversation.').closest('[role="note"]')

      expect(view.getByRole('log')).toContainElement(note as HTMLElement)
      expect(note).toHaveTextContent(/^just now\s*Anonymous closed the conversation\.$/)
      expect(view.getByRole('contentinfo')).not.toHaveTextContent('closed the conversation')
    })

    it('stays open for the agent, as a transferred conversation, when the state no longer lists it', async () => {
      const view = await openWindow()

      await pushStateWithoutSession()

      expect(view.getByRole('region', { name: 'Support #1' })).toBeInTheDocument()
      expect(
        view.getByText('This conversation was transferred to another chat.'),
      ).toBeInTheDocument()
      expect(view.queryByLabelText('Message')).not.toBeInTheDocument()
      expect(view.queryByRole('button', { name: 'Disconnect' })).not.toBeInTheDocument()

      await view.events.click(view.getByRole('button', { name: 'Close window' }))

      expect(view.queryByRole('region', { name: 'Support #1' })).not.toBeInTheDocument()
    })

    it('tells how a conversation ended once the session pushes it, after the state dropped it', async () => {
      const view = await openWindow()

      await pushStateWithoutSession()
      await pushUpdate({ closedBy: 'Anonymous' })

      expect(await view.findByText('Anonymous closed the conversation.')).toBeInTheDocument()
      expect(
        view.queryByText('This conversation was transferred to another chat.'),
      ).not.toBeInTheDocument()
    })

    // A reconnect subscribes again, and the server refuses a session that is back in a queue.
    it('stays quiet when the subscription is refused after the state dropped the session', async () => {
      const view = await openWindow()

      await pushStateWithoutSession()
      await refuseSubscription()

      expect(useNotifications().notifications.value).toHaveLength(0)
      expect(
        view.getByText('This conversation was transferred to another chat.'),
      ).toBeInTheDocument()
    })

    // The session pushes to every window that follows it, not only to the agent who runs it.
    describe('when a colleague accepts the transferred conversation', () => {
      const transferredMessage = chatMessage(2, '<div>Still down</div>', '2026-11-03T11:02:00Z')

      const transferAway = async (view: Awaited<ReturnType<typeof openWindow>>) => {
        mockChatSession(
          chatSession(1, {
            state: EnumChatSessionState.Waiting,
            user: currentAgent,
            topic: salesTopic,
          }),
          [customerMessage],
        )

        await pushStateWithoutSession()

        expect(
          await view.findByText('This conversation was transferred to another chat.'),
        ).toBeInTheDocument()

        mockChatSession({ ...runningSession(1, colleague), topic: salesTopic }, [customerMessage])
      }

      const expectColleaguesWindow = async (view: Awaited<ReturnType<typeof openWindow>>) => {
        expect(
          await view.findByText('This conversation is handled by Other Agent.'),
        ).toBeInTheDocument()
        expect(view.getByRole('img', { name: 'Online' })).toBeInTheDocument()
        expect(view.queryByRole('img', { name: 'Closed' })).not.toBeInTheDocument()
        expect(view.queryByLabelText('Message')).not.toBeInTheDocument()
        expect(view.queryByRole('button', { name: 'Disconnect' })).not.toBeInTheDocument()
        expect(view.getByRole('button', { name: 'Close window' })).toBeInTheDocument()
      }

      it('reads like their window, and follows it, in a topic the agent handles', async () => {
        const view = await openWindow([customerMessage])

        await transferAway(view)

        await pushRunningSessions([{ ...runningSession(1, colleague), topic: salesTopic }])

        await expectColleaguesWindow(view)

        await pushUpdate({ message: transferredMessage })

        expect(await view.findByText('Still down')).toBeInTheDocument()
      })

      // The state covers the agent's topics only; the first push tells that someone took the session.
      it('reads like their window, and follows it, in a topic the agent does not handle', async () => {
        const view = await openWindow([customerMessage])

        await transferAway(view)

        await pushUpdate({ message: transferredMessage })

        expect(await view.findByText('Still down')).toBeInTheDocument()

        await expectColleaguesWindow(view)
      })
    })

    it('tells the agent when the subscription is refused while they run the session', async () => {
      const view = await openWindow()

      await view.findByLabelText('Message')

      await refuseSubscription()

      await waitUntil(() => useNotifications().notifications.value.length === 1)
    })
  })

  // What a search result opens: the agent reads the conversation, and writes into it only when it
  //   is their own and still going on.
  describe('when the session was found through search', () => {
    const closedMessage = chatMessage(1, '<div>My VPN is down</div>', '2026-11-03T11:00:00Z')

    it('shows a closed conversation as finished, with its history', async () => {
      const view = await openFoundWindow(
        chatSession(5, { state: EnumChatSessionState.Closed, user: colleague }),
        [closedMessage],
      )

      expect(await view.findByText('My VPN is down')).toBeInTheDocument()
      expect(view.getByRole('img', { name: 'Closed' })).toBeInTheDocument()
      expect(view.getByText('This conversation is closed.')).toBeInTheDocument()
      expect(view.queryByLabelText('Message')).not.toBeInTheDocument()
      expect(view.queryByRole('button', { name: 'Disconnect' })).not.toBeInTheDocument()

      // Nothing more is pushed for it, so the window does not stay subscribed.
      expect(getChatSessionUpdatesSubscriptionHandler().closed()).toBe(true)

      await view.events.click(view.getByRole('button', { name: 'Close window' }))

      expect(view.queryByRole('region', { name: 'Support #5' })).not.toBeInTheDocument()
    })

    it("shows a colleague's running conversation read-only, and follows it", async () => {
      const view = await openFoundWindow(runningSession(5, colleague), [closedMessage])

      expect(await view.findByText('My VPN is down')).toBeInTheDocument()
      expect(view.getByRole('img', { name: 'Online' })).toBeInTheDocument()
      expect(view.getByText('This conversation is handled by Other Agent.')).toBeInTheDocument()
      expect(view.queryByLabelText('Message')).not.toBeInTheDocument()
      expect(view.queryByRole('button', { name: 'Disconnect' })).not.toBeInTheDocument()
      expect(getChatSessionUpdatesSubscriptionHandler().closed()).toBe(false)

      await pushUpdate({
        message: chatMessage(2, '<div>Still down</div>', '2026-11-03T11:02:00Z'),
      })

      expect(await view.findByText('Still down')).toBeInTheDocument()

      await pushUpdate({ closedBy: 'Anonymous' })

      expect(await view.findByText('Anonymous closed the conversation.')).toBeInTheDocument()
    })

    // Nothing in the window reads as ending a conversation that is not the agent's.
    it("lets the agent close the window of a colleague's running conversation, and nothing more", async () => {
      const view = await openFoundWindow(runningSession(5, colleague), [closedMessage])

      await view.findByText('This conversation is handled by Other Agent.')

      expect(view.queryByRole('button', { name: 'Close' })).not.toBeInTheDocument()

      await view.events.click(view.getByRole('button', { name: 'Close window' }))

      expect(view.queryByRole('region', { name: 'Support #5' })).not.toBeInTheDocument()
      expect(getGraphQLMockCalls(ChatSessionEndDocument)).toHaveLength(0)
    })

    // The server leaves naming, tagging and transferring to the agent of the session.
    it("offers no renaming, tagging or transfer of a colleague's conversation", async () => {
      mockAgentState({ runningSessions: [], topics: [supportTopic, salesTopic] })
      mockChatSession(runningSession(5, colleague), [closedMessage])

      const view = await visitView('/chat/session/5')

      await view.findByText('This conversation is handled by Other Agent.')

      expect(
        view.getByRole('heading', { level: 2, name: 'Support #5' }).closest('[role="button"]'),
      ).toBeNull()

      await view.events.click(view.getByRole('button', { name: 'Additional actions' }))

      const items = (await view.findAllByRole('menuitem')).map((item) => item.textContent?.trim())

      expect(items).toEqual(['Turn chat into a ticket', 'Show meta data'])
    })

    it('shows a conversation back in a queue read-only, and stays quiet about its refused subscription', async () => {
      const view = await openFoundWindow(
        chatSession(5, { state: EnumChatSessionState.Waiting, user: colleague }),
        [closedMessage],
      )

      expect(await view.findByText('My VPN is down')).toBeInTheDocument()
      expect(view.getByRole('img', { name: 'Waiting' })).toBeInTheDocument()
      expect(view.getByText('This conversation is waiting for an agent.')).toBeInTheDocument()
      expect(view.queryByLabelText('Message')).not.toBeInTheDocument()

      await refuseSubscription()

      expect(useNotifications().notifications.value).toHaveLength(0)
    })

    // The subscription refused for the queue is over: only a new one brings what is said from now on.
    it('lets the agent write once they accept a conversation they found in a queue, and follows it', async () => {
      const view = await openFoundWindow(
        chatSession(5, { state: EnumChatSessionState.Waiting, user: colleague }),
        [closedMessage],
      )

      expect(
        await view.findByText('This conversation is waiting for an agent.'),
      ).toBeInTheDocument()

      await refuseSubscription()

      const accepted = runningSession(5, currentAgent)

      mockChatSession(accepted, [closedMessage])

      await pushRunningSessions([accepted])

      expect(await view.findByLabelText('Message')).toBeInTheDocument()
      expect(view.getByRole('button', { name: 'Disconnect' })).toBeInTheDocument()
      expect(view.getByRole('img', { name: 'Online' })).toBeInTheDocument()
      expect(getGraphQLMockCalls(ChatSessionUpdatesDocument)).toHaveLength(2)

      await pushUpdate({
        message: chatMessage(2, '<div>Still down</div>', '2026-11-03T11:02:00Z'),
      })

      expect(await view.findByText('Still down')).toBeInTheDocument()
    })

    it('names the colleague who accepts a conversation the agent found in a queue, and follows it', async () => {
      const view = await openFoundWindow(chatSession(5, { state: EnumChatSessionState.Waiting }), [
        closedMessage,
      ])

      expect(
        await view.findByText('This conversation is waiting for an agent.'),
      ).toBeInTheDocument()

      await refuseSubscription()

      const accepted = runningSession(5, colleague)

      mockChatSession(accepted, [closedMessage])

      await pushRunningSessions([accepted])

      expect(
        await view.findByText('This conversation is handled by Other Agent.'),
      ).toBeInTheDocument()
      expect(view.getByRole('img', { name: 'Online' })).toBeInTheDocument()
      expect(view.queryByLabelText('Message')).not.toBeInTheDocument()
      expect(getGraphQLMockCalls(ChatSessionUpdatesDocument)).toHaveLength(2)

      await pushUpdate({
        message: chatMessage(2, '<div>Still down</div>', '2026-11-03T11:02:00Z'),
      })

      expect(await view.findByText('Still down')).toBeInTheDocument()
    })

    // What the reload brings was said to the colleague.
    it('counts nothing as unread in a conversation a colleague accepted', async () => {
      const view = await openFoundWindow(chatSession(5, { state: EnumChatSessionState.Waiting }), [
        closedMessage,
      ])

      await view.findByText('This conversation is waiting for an agent.')

      await refuseSubscription()

      const accepted = runningSession(5, colleague)

      mockChatSession(accepted, [
        closedMessage,
        chatMessage(2, '<div>Still down</div>', '2026-11-03T11:02:00Z'),
      ])

      await pushRunningSessions([accepted])

      expect(await view.findByText('Still down')).toBeInTheDocument()
      expect(useChatUnreadMessagesStore().total).toBe(0)
    })

    it('names the colleague who runs a conversation now, when it changed hands', async () => {
      const view = await openFoundWindow(runningSession(5, colleague), [closedMessage])

      expect(
        await view.findByText('This conversation is handled by Other Agent.'),
      ).toBeInTheDocument()

      const third = { ...colleague, id: convertToGraphQLId('User', 4), fullname: 'Third Agent' }

      // Asked again after the change of hands, the session agrees with the state.
      mockChatSession(runningSession(5, third), [closedMessage])

      await pushRunningSessions([runningSession(5, third)])

      expect(
        await view.findByText('This conversation is handled by Third Agent.'),
      ).toBeInTheDocument()
    })

    // The state covers the agent's topics only: what happens to the session elsewhere, the session
    //   itself tells, once asked or once it pushes again.
    it("tells when a colleague's conversation goes back to a queue, and who takes it from there", async () => {
      const running = runningSession(5, colleague)

      mockAgentState({ runningSessions: [running] })
      mockChatSession(running, [closedMessage])

      const view = await visitView('/chat/session/5')

      await view.findByRole('region', { name: 'Support #5' })

      expect(
        await view.findByText('This conversation is handled by Other Agent.'),
      ).toBeInTheDocument()

      mockChatSession(chatSession(5, { state: EnumChatSessionState.Waiting, user: colleague }), [
        closedMessage,
      ])

      await pushRunningSessions([])

      expect(
        await view.findByText('This conversation is waiting for an agent.'),
      ).toBeInTheDocument()
      expect(view.getByRole('img', { name: 'Waiting' })).toBeInTheDocument()

      const third = { ...colleague, id: convertToGraphQLId('User', 4), fullname: 'Third Agent' }

      mockChatSession(runningSession(5, third), [closedMessage])

      await pushUpdate({
        message: chatMessage(2, '<div>Still down</div>', '2026-11-03T11:02:00Z'),
      })

      expect(await view.findByText('Still down')).toBeInTheDocument()
      expect(
        await view.findByText('This conversation is handled by Third Agent.'),
      ).toBeInTheDocument()
    })

    it("opens the agent's own running conversation as usual", async () => {
      const own = runningSession(5, currentAgent)

      mockAgentState({ runningSessions: [own] })
      mockChatSession(own, [closedMessage])

      const view = await visitView('/chat/session/5')

      await view.findByRole('region', { name: 'Support #5' })

      expect(await view.findByLabelText('Message')).toBeInTheDocument()
      expect(view.getByRole('button', { name: 'Disconnect' })).toBeInTheDocument()
      expect(view.queryByRole('button', { name: 'Close window' })).not.toBeInTheDocument()
      expect(view.getAllByRole('region')).toHaveLength(1)
    })
  })

  describe('disconnecting', () => {
    it('ends the conversation after a confirmation', async () => {
      mockChatSessionEndMutation({
        chatSessionEnd: {
          session: { ...session, state: EnumChatSessionState.Closed },
          errors: null,
        },
      })

      const view = await openWindow()

      await view.events.click(await view.findByRole('button', { name: 'Disconnect' }))

      const dialog = await view.findByRole('dialog')

      expect(dialog).toHaveTextContent('Are you sure you want to end the conversation?')
      expect(dialog).toHaveTextContent('This will end the conversation with Support #1.')

      await view.events.click(view.getByRole('button', { name: 'End conversation' }))

      const calls = await waitForChatSessionEndMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({ sessionId: session.id })
      expect(await view.findByRole('img', { name: 'Closed' })).toBeInTheDocument()
    })

    it('names the agent who ended it from their first and last name when the full name is not readable', async () => {
      mockChatSessionEndMutation({
        chatSessionEnd: {
          session: {
            ...session,
            state: EnumChatSessionState.Closed,
            user: { ...currentAgent, fullname: null },
          },
          errors: null,
        },
      })

      const view = await openWindow()

      await view.events.click(await view.findByRole('button', { name: 'Disconnect' }))
      await view.events.click(await view.findByRole('button', { name: 'End conversation' }))

      expect(await view.findByText('Chat Agent closed the conversation.')).toBeInTheDocument()
    })

    it('leaves the conversation alone when the agent cancels', async () => {
      const view = await openWindow()

      await view.events.click(await view.findByRole('button', { name: 'Disconnect' }))
      await view.events.click(await view.findByRole('button', { name: 'Cancel & go back' }))

      expect(getGraphQLMockCalls(ChatSessionEndDocument)).toHaveLength(0)
      expect(view.getByRole('img', { name: 'Online' })).toBeInTheDocument()
    })

    it('ends nothing when the customer closed the conversation while the dialog was open', async () => {
      const view = await openWindow()

      await view.events.click(await view.findByRole('button', { name: 'Disconnect' }))
      await view.findByRole('dialog')

      await pushUpdate({ closedBy: 'Anonymous' })

      await view.events.click(view.getByRole('button', { name: 'End conversation' }))

      expect(getGraphQLMockCalls(ChatSessionEndDocument)).toHaveLength(0)
      expect(view.getByText('Anonymous closed the conversation.')).toBeInTheDocument()
    })

    it('tells the agent when the conversation cannot be ended and keeps it open', async () => {
      mockChatSessionEndMutationError('You are not running this chat session.', {
        type: GraphQLErrorTypes.Forbidden,
      })

      const view = await openWindow()

      await view.events.click(await view.findByRole('button', { name: 'Disconnect' }))
      await view.events.click(await view.findByRole('button', { name: 'End conversation' }))

      await waitUntil(() => useNotifications().notifications.value.length === 1)

      expect(useNotifications().notifications.value).toEqual([
        expect.objectContaining({ message: 'You are not running this chat session.' }),
      ])
      expect(view.getByRole('img', { name: 'Online' })).toBeInTheDocument()
      expect(view.getByRole('button', { name: 'Disconnect' })).toBeEnabled()
    })
  })

  describe('renaming', () => {
    const renamedSession = { ...session, name: 'Pricing question' }

    const openWindowOf = async (shownSession: typeof session) => {
      mockAgentState({ runningSessions: [shownSession] })
      mockChatSession(shownSession, [customerMessage])

      const view = await visitView('/chat')

      await view.findByText('Hello')

      return view
    }

    it('names the conversation from its title on Enter', async () => {
      mockChatSessionRenameMutation({
        chatSessionRename: { session: renamedSession, errors: null },
      })

      const view = await openWindowOf(session)

      await view.events.click(view.getByRole('heading', { level: 2, name: 'Support #1' }))

      expect(view.getByRole('textbox', { name: 'Edit chat name' })).toHaveValue('Support')

      await view.events.clear(view.getByRole('textbox', { name: 'Edit chat name' }))
      await view.events.type(
        view.getByRole('textbox', { name: 'Edit chat name' }),
        'Pricing question{Enter}',
      )

      const calls = await waitForChatSessionRenameMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({ sessionId: session.id, name: 'Pricing question' })
      expect(await view.findByRole('region', { name: 'Pricing question #1' })).toBeInTheDocument()
      expect(
        view.getByRole('heading', { level: 2, name: 'Pricing question #1' }),
      ).toBeInTheDocument()
      expect(view.queryByRole('textbox', { name: 'Edit chat name' })).not.toBeInTheDocument()
      expect(view.getByText('Chat renamed successfully.')).toBeInTheDocument()
    })

    it('edits the name the conversation has, and saves nothing when it stays the same', async () => {
      const view = await openWindowOf(renamedSession)

      await view.events.click(view.getByRole('heading', { level: 2, name: 'Pricing question #1' }))

      expect(view.getByRole('textbox', { name: 'Edit chat name' })).toHaveValue('Pricing question')

      await view.events.type(view.getByRole('textbox', { name: 'Edit chat name' }), '{Enter}')

      expect(view.queryByRole('textbox', { name: 'Edit chat name' })).not.toBeInTheDocument()
      expect(getGraphQLMockCalls(ChatSessionRenameDocument)).toHaveLength(0)
    })

    it('cannot save an empty name', async () => {
      const view = await openWindowOf(renamedSession)

      await view.events.click(view.getByRole('heading', { level: 2, name: 'Pricing question #1' }))
      await view.events.clear(view.getByRole('textbox', { name: 'Edit chat name' }))

      expect(view.getByRole('button', { name: 'Save changes' })).toBeDisabled()

      await view.events.type(view.getByRole('textbox', { name: 'Edit chat name' }), '{Enter}')

      expect(view.getByRole('textbox', { name: 'Edit chat name' })).toBeInTheDocument()
      expect(getGraphQLMockCalls(ChatSessionRenameDocument)).toHaveLength(0)
    })

    it('still names a closed conversation', async () => {
      const closedSession = { ...session, state: EnumChatSessionState.Closed }

      mockChatSessionRenameMutation({
        chatSessionRename: {
          session: { ...renamedSession, state: closedSession.state },
          errors: null,
        },
      })

      const view = await openWindowOf(closedSession)

      await view.events.click(view.getByRole('heading', { level: 2, name: 'Support #1' }))
      await view.events.clear(view.getByRole('textbox', { name: 'Edit chat name' }))
      await view.events.type(
        view.getByRole('textbox', { name: 'Edit chat name' }),
        'Pricing question{Enter}',
      )

      const calls = await waitForChatSessionRenameMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({ sessionId: session.id, name: 'Pricing question' })
    })

    it('tells no end time for a conversation that was over when it loaded, also once renamed', async () => {
      const closedSession = { ...session, state: EnumChatSessionState.Closed }

      mockChatSessionRenameMutation({
        chatSessionRename: {
          session: {
            ...closedSession,
            name: 'Pricing question',
            updatedAt: new Date().toISOString(),
          },
          errors: null,
        },
      })

      const view = await openWindowOf(closedSession)

      const endingNote = () =>
        view.getByText('This conversation is closed.').closest('[role="note"]')

      expect(endingNote()).toHaveTextContent(/^This conversation is closed\.$/)

      await view.events.click(view.getByRole('heading', { level: 2, name: 'Support #1' }))
      await view.events.clear(view.getByRole('textbox', { name: 'Edit chat name' }))
      await view.events.type(
        view.getByRole('textbox', { name: 'Edit chat name' }),
        'Pricing question{Enter}',
      )

      expect(await view.findByRole('region', { name: 'Pricing question #1' })).toBeInTheDocument()
      expect(endingNote()).toHaveTextContent(/^This conversation is closed\.$/)
    })
  })

  describe('when the conversation does not load', () => {
    const openWindowWithoutConversation = async () => {
      mockAgentState({ runningSessions: [session] })
      mockChatSessionQuery(() => Promise.reject(new Error('Network down')))

      const view = await visitView('/chat')

      await view.findByRole('region', { name: 'Support #1' })
      await view.findByText('The conversation could not be loaded.')

      return view
    }

    it('keeps the window with its title and shows the conversation once a retry loads it', async () => {
      const view = await openWindowWithoutConversation()

      expect(view.getByRole('heading', { level: 2, name: 'Support #1' })).toBeInTheDocument()

      await view.events.click(view.getByRole('heading', { level: 2, name: 'Support #1' }))

      expect(view.queryByRole('textbox', { name: 'Edit chat name' })).not.toBeInTheDocument()
      expect(view.queryByRole('log')).not.toBeInTheDocument()
      expect(view.queryByLabelText('Message')).not.toBeInTheDocument()
      // Theirs to end for the customer, conversation or not.
      expect(view.getByRole('button', { name: 'Disconnect' })).toBeInTheDocument()

      mockChatSession(session, [customerMessage])

      await view.events.click(view.getByRole('button', { name: 'Try again' }))

      expect(await view.findByText('Hello')).toBeInTheDocument()
      expect(view.getByLabelText('Message')).toBeInTheDocument()
      expect(view.queryByText('The conversation could not be loaded.')).not.toBeInTheDocument()
    })

    it('keeps the unread messages through the retry, which shows them', async () => {
      useChatUnreadMessagesStore().addUnreadMessage(session.id, customerMessage.id)

      const view = await openWindowWithoutConversation()

      mockChatSession(session, [customerMessage])

      await view.events.click(view.getByRole('button', { name: 'Try again' }))

      expect(await view.findByText('Hello')).toBeInTheDocument()
      expect(view.getByText('Unread messages')).toBeInTheDocument()
      expect(useChatUnreadMessagesStore().total).toBe(1)
    })

    it('offers no close while the agent still runs the session, which the next state would bring back', async () => {
      const view = await openWindowWithoutConversation()

      expect(view.getByRole('button', { name: 'Try again' })).toBeInTheDocument()
      expect(view.queryByRole('button', { name: 'Close window' })).not.toBeInTheDocument()
    })

    it('lets the agent close the window once the session is no longer theirs', async () => {
      const view = await openWindowWithoutConversation()

      await pushStateWithoutSession()

      await view.events.click(await view.findByRole('button', { name: 'Close window' }))

      expect(view.queryByRole('region', { name: 'Support #1' })).not.toBeInTheDocument()
    })
  })

  it('reads its conversation once the agent comes to the window', async () => {
    const view = await openWindow([customerMessage])

    useChatUnreadMessagesStore().addUnreadMessage(session.id, customerMessage.id)

    await view.events.click(view.getByLabelText('Message'))

    expect(useChatUnreadMessagesStore().total).toBe(0)
  })

  // The focus the browser gives back to the input reads nothing, and neither does Enter on a draft.
  it('reads its conversation once the agent answers from the input they left the tab from', async () => {
    mockChatSessionMessageAddMutation({
      chatSessionMessageAdd: {
        message: chatMessage(2, '<div>Answer</div>', '2026-11-03T11:00:20Z', currentAgent),
        errors: null,
      },
    })

    const view = await openWindow([customerMessage])

    const input = await view.findByLabelText('Message')

    await view.events.type(input, 'Answer')

    window.dispatchEvent(new Event('blur'))
    useChatUnreadMessagesStore().addUnreadMessage(session.id, customerMessage.id)
    window.dispatchEvent(new Event('focus'))
    input.dispatchEvent(new FocusEvent('focusin', { bubbles: true }))

    await view.events.keyboard('{Enter}')

    expect(useChatUnreadMessagesStore().total).toBe(0)
  })

  // A click into the window, to read or copy, puts the focus on the window itself.
  it('keeps its conversation unread on a click elsewhere in the window, which takes the focus itself', async () => {
    const view = await openWindow([customerMessage])

    useChatUnreadMessagesStore().addUnreadMessage(session.id, customerMessage.id)

    await view.events.click(await view.findByRole('log'))

    expect(view.getByRole('region', { name: 'Support #1' })).toHaveFocus()
    expect(useChatUnreadMessagesStore().total).toBe(1)
  })

  describe('where the unread messages begin', () => {
    const answer = chatMessage(
      2,
      '<div>How can I help?</div>',
      '2026-11-03T11:00:20Z',
      currentAgent,
    )

    const stillThere = chatMessage(3, '<div>Still there?</div>', '2026-11-03T11:00:40Z')

    const hello = chatMessage(4, '<div>Hello?</div>', '2026-11-03T11:00:50Z')

    const divider = (view: Awaited<ReturnType<typeof openWindow>>) =>
      view.queryByText('Unread messages')

    const messagesBelowDivider = (view: Awaited<ReturnType<typeof openWindow>>) => {
      const label = view.getByText('Unread messages')

      return view
        .getAllByTestId('chat-message')
        .filter(
          (bubble) => label.compareDocumentPosition(bubble) & Node.DOCUMENT_POSITION_FOLLOWING,
        )
        .map((bubble) => bubble.textContent)
    }

    const customerWritesMeanwhile = async () => {
      const view = await openWindow([customerMessage, answer])

      await view.findByText('How can I help?')

      await pushUpdate({ message: stillThere })
      await pushUpdate({ message: hello })

      return view
    }

    it('shows a divider before the first message of the customer the agent has not read', async () => {
      const view = await customerWritesMeanwhile()

      expect(messagesBelowDivider(view)).toEqual(['Still there?', 'Hello?'])
      expect(useChatUnreadMessagesStore().total).toBe(2)
    })

    it('starts the messages below the divider apart from the one before', async () => {
      const view = await openWindow([customerMessage])

      await view.findByText('Hello')

      // Twenty seconds after the one before, from the same side, so a follow-up without the divider.
      await pushUpdate({
        message: chatMessage(3, '<div>Still there?</div>', '2026-11-03T11:00:20Z'),
      })

      const [, unread] = view
        .getAllByTestId('chat-message')
        .map((bubble) => bubble.parentElement?.parentElement)

      expect(divider(view)).toBeInTheDocument()
      expect(unread).not.toHaveClass('-mt-4')
    })

    it('takes the divider away once the agent comes to the message input', async () => {
      const view = await customerWritesMeanwhile()

      await view.events.click(view.getByLabelText('Message'))

      expect(divider(view)).not.toBeInTheDocument()
    })

    it('keeps the divider on a click on the thread', async () => {
      const view = await customerWritesMeanwhile()

      await view.events.click(view.getByRole('log'))

      expect(messagesBelowDivider(view)).toEqual(['Still there?', 'Hello?'])
      expect(useChatUnreadMessagesStore().total).toBe(2)
    })

    it('shows no divider for what arrives while the agent is in the message input', async () => {
      const view = await openWindow([customerMessage])

      await view.events.click(await view.findByLabelText('Message'))

      await pushUpdate({ message: stillThere })

      expect(await view.findByText('Still there?')).toBeInTheDocument()
      expect(divider(view)).not.toBeInTheDocument()
    })

    it('shows the divider for what arrives while the agent reads back in the thread', async () => {
      const view = await openWindow([customerMessage])

      await view.events.click(await view.findByText('Hello'))

      await pushUpdate({ message: stillThere })

      expect(view.getByRole('region', { name: 'Support #1' })).toHaveFocus()
      expect(messagesBelowDivider(view)).toEqual(['Still there?'])
    })

    // The notification counts at the app root, also before the agent opens the Chat page.
    it('shows the divider in the right place in a window that opens after the messages were counted', async () => {
      const { addUnreadMessage } = useChatUnreadMessagesStore()

      // The one missed while the connection was down is counted after the newer one.
      addUnreadMessage(session.id, hello.id)
      addUnreadMessage(session.id, stillThere.id)

      const view = await openWindow([customerMessage, answer, stillThere, hello])

      await view.findByText('Hello?')

      expect(messagesBelowDivider(view)).toEqual(['Still there?', 'Hello?'])
    })

    // The listener only follows the agent's own sessions; the window reports what a reconnect brings.
    it("shows no divider in a colleague's conversation the agent only reads", async () => {
      const found = runningSession(5, colleague)

      const view = await openFoundWindow(found, [customerMessage])

      await view.findByText('This conversation is handled by Other Agent.')

      await pushUpdate({ message: stillThere })

      expect(await view.findByText('Still there?')).toBeInTheDocument()

      mockAgentState({ runningSessions: [] })
      mockChatSession(found, [customerMessage, stillThere, hello])

      emitter.emit('reconnected')

      expect(await view.findByText('Hello?')).toBeInTheDocument()
      expect(divider(view)).not.toBeInTheDocument()
      expect(useChatUnreadMessagesStore().total).toBe(0)
    })

    // The session keeps its agent when it is transferred, but it is no longer the agent's to run.
    it('counts nothing as unread that a conversation that went elsewhere missed', async () => {
      const view = await openWindow([customerMessage])

      await view.findByText('Hello')

      await pushStateWithoutSession()

      await view.findByText('This conversation was transferred to another chat.')

      // The reconnect asks for the state again, which agrees with what was pushed.
      mockAgentState({ runningSessions: [] })
      mockChatSession(session, [customerMessage, stillThere])

      emitter.emit('reconnected')

      expect(await view.findByText('Still there?')).toBeInTheDocument()
      expect(divider(view)).not.toBeInTheDocument()
      expect(useChatUnreadMessagesStore().total).toBe(0)
    })

    // A reconnect asks for both again, and the state may answer last.
    it('counts nothing as unread that a reconnect brings for a conversation that went elsewhere before the state says so', async () => {
      const view = await openWindow([customerMessage])

      await view.findByText('Hello')

      mockAgentState({ runningSessions: [session] })
      mockChatSession({ ...session, state: EnumChatSessionState.Waiting }, [
        customerMessage,
        stillThere,
      ])

      emitter.emit('reconnected')

      expect(await view.findByText('Still there?')).toBeInTheDocument()
      expect(divider(view)).not.toBeInTheDocument()
      expect(useChatUnreadMessagesStore().total).toBe(0)
    })

    it('drops the unread messages of a conversation that was transferred', async () => {
      const view = await customerWritesMeanwhile()

      // The state dropping the session loads it again, which tells that it waits in a queue.
      mockChatSession({ ...session, state: EnumChatSessionState.Waiting }, [
        customerMessage,
        answer,
        stillThere,
        hello,
      ])

      await pushStateWithoutSession()

      expect(
        await view.findByText('This conversation was transferred to another chat.'),
      ).toBeInTheDocument()
      expect(divider(view)).not.toBeInTheDocument()
      expect(useChatUnreadMessagesStore().total).toBe(0)
    })

    it('drops the unread messages of a conversation a colleague took over', async () => {
      const view = await customerWritesMeanwhile()

      // A change of hands loads the conversation again, which names the colleague as well.
      mockChatSession(runningSession(1, colleague), [customerMessage, answer])

      await pushRunningSessions([runningSession(1, colleague)])

      expect(
        await view.findByText('This conversation is handled by Other Agent.'),
      ).toBeInTheDocument()
      expect(divider(view)).not.toBeInTheDocument()
      expect(useChatUnreadMessagesStore().total).toBe(0)
    })

    it('keeps the unread messages of a conversation that ended until the agent reads them', async () => {
      const view = await customerWritesMeanwhile()

      await pushUpdate({ leftBy: 'Anonymous' })
      await pushStateWithoutSession()

      expect(await view.findByText('Anonymous left the conversation.')).toBeInTheDocument()
      expect(messagesBelowDivider(view)).toEqual(['Still there?', 'Hello?'])
      expect(useChatUnreadMessagesStore().total).toBe(2)

      // Without a message input to come to, a click into the window reads it.
      await view.events.click(view.getByRole('log'))

      expect(divider(view)).not.toBeInTheDocument()
      expect(useChatUnreadMessagesStore().total).toBe(0)
    })

    // A customer who closes the widget is dropped from the state first, like after a transfer.
    it('keeps the unread messages of a conversation the state drops before its end is pushed', async () => {
      const view = await customerWritesMeanwhile()

      await pushStateWithoutSession()

      expect(
        await view.findByText('This conversation was transferred to another chat.'),
      ).toBeInTheDocument()
      expect(useChatUnreadMessagesStore().total).toBe(2)

      await pushUpdate({ closedBy: 'Anonymous' })

      expect(await view.findByText('Anonymous closed the conversation.')).toBeInTheDocument()
      expect(messagesBelowDivider(view)).toEqual(['Still there?', 'Hello?'])
      expect(useChatUnreadMessagesStore().total).toBe(2)
    })

    it('keeps the unread messages of a conversation the state drops and that loads as closed', async () => {
      const view = await customerWritesMeanwhile()

      mockChatSession({ ...session, state: EnumChatSessionState.Closed }, [
        customerMessage,
        answer,
        stillThere,
        hello,
      ])

      await pushStateWithoutSession()

      expect(await view.findByText('This conversation is closed.')).toBeInTheDocument()
      expect(messagesBelowDivider(view)).toEqual(['Still there?', 'Hello?'])
      expect(useChatUnreadMessagesStore().total).toBe(2)
    })
  })

  describe('turning the chat into a ticket', () => {
    const createRoute = () => getTestRouter().currentRoute.value

    // The create route is the agent's only with the ticket permission.
    beforeEach(() => {
      mockChatAgent({ permissions: ['chat.agent', 'ticket.agent'] })
    })

    const closeWindow = async () => {
      const view = await openWindow()

      await pushUpdate({ closedBy: 'Anonymous' })

      await view.findByText('Anonymous closed the conversation.')

      return view
    }

    const openMenu = async (view: Awaited<ReturnType<typeof openWindow>>) => {
      await view.events.click(view.getByRole('button', { name: 'Additional actions' }))

      return view.findByRole('menu')
    }

    it('is offered in the window menu while the chat is running, not yet in the footer', async () => {
      const view = await openWindow()

      await view.findByLabelText('Message')

      expect(
        view.queryByRole('button', { name: 'Turn chat into a ticket' }),
      ).not.toBeInTheDocument()

      await view.events.click(within(await openMenu(view)).getByText('Turn chat into a ticket'))

      await waitFor(() => expect(createRoute().name).toBe('TicketCreate'))

      expect(createRoute().query).toEqual({ chatSessionId: session.id })
    })

    it('opens a fresh ticket create tab with the session once the chat ended', async () => {
      const view = await closeWindow()

      await view.events.click(view.getByRole('button', { name: 'Turn chat into a ticket' }))

      await waitFor(() => expect(createRoute().name).toBe('TicketCreate'))

      expect(createRoute().query).toEqual({ chatSessionId: session.id })
      expect(createRoute().params.tabId).toBeTruthy()
      expect(getGraphQLMockCalls(ChatSessionEndDocument)).toHaveLength(0)
    })

    it('is not offered for a conversation that was transferred away', async () => {
      const view = await openWindow()

      await pushStateWithoutSession()

      await view.findByText('This conversation was transferred to another chat.')

      expect(
        view.queryByRole('button', { name: 'Turn chat into a ticket' }),
      ).not.toBeInTheDocument()

      expect(
        within(await openMenu(view)).queryByText('Turn chat into a ticket'),
      ).not.toBeInTheDocument()
    })

    describe('for an agent without a group to create tickets in', () => {
      const reason = 'You have no permission to create tickets in any group.'

      beforeEach(() => {
        mockChatPreferences({ hasTicketCreateAccess: false })
      })

      it('is marked disabled and tells why, on hover and to a screen reader', async () => {
        const view = await closeWindow()

        const button = view.getByRole('button', { name: 'Turn chat into a ticket' })

        await waitFor(() => expect(button).toHaveAttribute('aria-disabled', 'true'))
        expect(button).toHaveAttribute('aria-description', reason)

        await view.events.hover(button)

        expect(await view.findByText(reason)).toBeInTheDocument()
      })

      it('is marked disabled in the window menu as well, with the reason', async () => {
        const view = await closeWindow()

        const item = within(await openMenu(view)).getByRole('button', {
          name: 'Turn chat into a ticket',
        })

        expect(item).toHaveAttribute('aria-disabled', 'true')
        expect(item).toHaveAttribute('aria-description', reason)

        await view.events.click(item)

        expect(createRoute().name).not.toBe('TicketCreate')
      })

      it('ignores a click', async () => {
        const view = await closeWindow()

        const button = view.getByRole('button', { name: 'Turn chat into a ticket' })

        await waitFor(() => expect(button).toHaveAttribute('aria-disabled', 'true'))

        await view.events.click(button)

        expect(createRoute().name).not.toBe('TicketCreate')
      })
    })
  })
})
