// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { generateObjectData } from '#tests/graphql/builders/index.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import type {
  KnowledgeBaseAnswerTranslation,
  OnlineNotification,
  Ticket,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import ActivityMessage from '../ActivityMessage.vue'

const now = vi.hoisted(() => {
  const now = new Date('2022-01-03 00:00:00')
  vi.setSystemTime(now)
  return now
})

// this is not required, but Vitest is bugged and does not hoist "now" otherwise
// https://github.com/vitest-dev/vitest/pull/4285/files
vi.mock('non-existing')

const userId = convertToGraphQLId('User', 100)

const renderActivityMessage = (activityProps: Partial<OnlineNotification> = {}) => {
  const finishedProps = {
    activity: {
      objectName: 'Ticket',
      typeName: 'update',
      createdBy: {
        id: userId,
        fullname: 'John Doe',
        firstname: 'John',
        lastname: 'Doe',
        active: true,
      },
      createdAt: new Date('2022-01-01 00:00:00').toISOString(),
      metaObject: generateObjectData<Ticket>('Ticket', {
        title: 'Ticket Title',
        id: convertToGraphQLId('Ticket', '1'),
        internalId: 1,
      }),
      ...activityProps,
    } as OnlineNotification,
  }

  return renderComponent(ActivityMessage, {
    props: finishedProps,
    router: true,
  })
}

describe('NotificationItem.vue', () => {
  afterEach(() => {
    vi.useRealTimers()
  })

  it('check update activity message output', () => {
    const view = renderActivityMessage()

    expect(view.container).toHaveTextContent('John Doe updated ticket Ticket Title')
  })

  it('check create activity message output', () => {
    const view = renderActivityMessage({
      typeName: 'create',
    })

    expect(view.container).toHaveTextContent('John Doe created ticket Ticket Title')
  })

  it('check that avatar exists', () => {
    const view = renderActivityMessage()

    const avatar = view.getByTestId('common-avatar')

    expect(avatar).toHaveTextContent('JD')
  })

  it('check that link exists', () => {
    const view = renderActivityMessage()

    const link = view.getByRole('link')
    expect(link).toHaveAttribute('href', '/tickets/1')
  })

  it('check that create date exists', () => {
    vi.setSystemTime(now)

    const view = renderActivityMessage()
    expect(view.getByText(/2 days ago/)).toBeInTheDocument()
  })

  it('check that default message and avatar for no meta object is visible', () => {
    const view = renderActivityMessage({
      metaObject: undefined,
      createdBy: undefined,
    })

    expect(view.container).toHaveTextContent('You can no longer see the ticket.')
    expect(view.getByIconName('lock')).toBeInTheDocument()
  })

  it('should emit "seen" event on click for none linked notifications', async () => {
    const view = renderActivityMessage({
      metaObject: undefined,
      createdBy: undefined,
    })

    const item = view.getByText('You can no longer see the ticket.')

    await view.events.click(item)

    expect(view.emitted().seen).toBeTruthy()
  })

  const renderKnowledgeBaseAnswerMessage = () =>
    renderActivityMessage({
      objectName: 'KnowledgeBase::Answer::Translation',
      typeName: 'create',
      metaObject: generateObjectData<KnowledgeBaseAnswerTranslation>(
        'KnowledgeBaseAnswerTranslation',
        {
          title: 'Reset your password',
          kbLocale: { systemLocale: { locale: 'en-us' } },
          answer: {
            id: convertToGraphQLId('KnowledgeBase::Answer', '1'),
            category: { id: convertToGraphQLId('KnowledgeBase::Category', '1') },
          },
        },
      ),
    })

  // Both answer pages live outside of the mobile app, so their links must be absolute. A relative
  //   one would be resolved against the mobile base and end up on the error page.
  it('links a knowledge base answer into the desktop view, which has an answer view', () => {
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])

    expect(renderKnowledgeBaseAnswerMessage().getByRole('link')).toHaveAttribute(
      'href',
      '/desktop/knowledge-base/locale/en-us/answer/1',
    )
  })

  it('links to the public answer page for a user without knowledge base permission', () => {
    mockPermissions(['ticket.agent'])

    expect(renderKnowledgeBaseAnswerMessage().getByRole('link')).toHaveAttribute(
      'href',
      '/help/en-us/1/1',
    )
  })

  it('no output for not existing builder', (context) => {
    context.skipConsole = true

    const view = renderActivityMessage({
      objectName: 'NotExisting',
    })

    expect(view.html()).not.toContain('a')
  })
})
