// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import {
  mockCalendarIcsFileEventsQuery,
  mockCalendarIcsFileEventsQueryError,
} from '#desktop/entities/calendar/ics-file/graphql/queries/events.mocks.ts'

import CommonCalendarPreviewFlyout from '../CommonCalendarPreviewFlyout.vue'

// FIXME: Is there any more logical way of mocking the default export and getting the mock reference back?!
//   Note that the following does not work as it results in the following error:
//   Error: [vitest] There was an error when mocking a module. If you are using "vi.mock" factory, make sure there are
//   no top level variables inside, since this call is hoisted to top of the file.
//   Read more: https://vitest.dev/api/vi.html#vi-mock
//   Caused by: ReferenceError: Cannot access 'openExternalLinkMock' before initialization
// const openExternalLinkMock = vi.fn()

vi.mock('#shared/utils/openExternalLink.ts', async () => ({
  default: vi.fn(),
}))

const { default: openExternalLinkMock } = await import('#shared/utils/openExternalLink.ts')

const meetingEvent = {
  __typename: 'CalendarIcsFileEvent' as const,
  title: 'Zammad Helpdesk Meeting',
  location: 'https://example.com/meeting/1234567890',
  startDate: '2026-06-29T08:00:00Z',
  endDate: '2026-06-29T16:00:00Z',
  organizer: 'nicole.braun@zammad.org',
  attendees: ['agent-1@example.com', 'zammad@localhost'],
  description: 'Hello together,\n\nJoin us here: https://meet.example.com/zammad',
}

const lunchEvent = {
  __typename: 'CalendarIcsFileEvent' as const,
  title: 'Lunch',
  location: null,
  startDate: '2026-06-29T12:00:00Z',
  endDate: '2026-06-29T12:30:00Z',
  organizer: null,
  attendees: [],
  description: null,
}

const renderOptions = {
  props: {
    fileId: convertToGraphQLId('Store', 1),
    fileType: 'text/calendar',
    fileName: 'calendar.ics',
  },
  router: true,
  global: {
    stubs: {
      teleport: true,
    },
  },
}

const renderCommonCalendarPreviewFlyout = async (events = [meetingEvent, lunchEvent]) => {
  mockCalendarIcsFileEventsQuery({ calendarIcsFileEvents: events })

  const result = renderComponent(CommonCalendarPreviewFlyout, renderOptions)

  await waitForNextTick()

  return result
}

describe('CommonCalendarPreviewFlyout.vue', () => {
  beforeAll(() => {
    mockApplicationConfig({
      api_path: '/api',
    })
  })

  it('renders every attribute of an event', async () => {
    const wrapper = await renderCommonCalendarPreviewFlyout()

    expect(wrapper.getByRole('complementary', { name: 'Preview calendar' })).toBeInTheDocument()
    expect(wrapper.getByRole('heading', { name: 'Preview calendar' })).toBeInTheDocument()

    const [meeting] = wrapper.getAllByRole('article')

    expect(
      within(meeting).getByRole('heading', { name: 'Zammad Helpdesk Meeting' }),
    ).toBeInTheDocument()

    expect(within(meeting).getByText('Location')).toBeInTheDocument()
    expect(within(meeting).getByText('https://example.com/meeting/1234567890')).toBeInTheDocument()

    expect(within(meeting).getByText('Start date')).toBeInTheDocument()
    expect(within(meeting).getByText('2026-06-29 08:00')).toBeInTheDocument()

    expect(within(meeting).getByText('End date')).toBeInTheDocument()
    expect(within(meeting).getByText('2026-06-29 16:00')).toBeInTheDocument()

    expect(within(meeting).getByText('Organizer')).toBeInTheDocument()
    expect(within(meeting).getByText('nicole.braun@zammad.org')).toBeInTheDocument()

    expect(within(meeting).getByText('Attendees')).toBeInTheDocument()
    expect(within(meeting).getByRole('list')).toBeInTheDocument()
    expect(within(meeting).getByText('agent-1@example.com')).toBeInTheDocument()
    expect(within(meeting).getByText('zammad@localhost')).toBeInTheDocument()

    expect(within(meeting).getByText('Description')).toBeInTheDocument()
    expect(within(meeting).getByText('Hello together,')).toBeInTheDocument()
    expect(within(meeting).getByText(/Join us here:/)).toBeInTheDocument()
  })

  it('renders URLs and email addresses as links', async () => {
    const wrapper = await renderCommonCalendarPreviewFlyout()

    const [meeting] = wrapper.getAllByRole('article')

    expect(
      within(meeting).getByRole('link', { name: 'https://example.com/meeting/1234567890' }),
    ).toHaveAttribute('href', 'https://example.com/meeting/1234567890')

    expect(
      within(meeting).getByRole('link', { name: 'https://meet.example.com/zammad' }),
    ).toHaveAttribute('href', 'https://meet.example.com/zammad')

    expect(within(meeting).getByRole('link', { name: 'nicole.braun@zammad.org' })).toHaveAttribute(
      'href',
      'mailto:nicole.braun@zammad.org',
    )

    expect(within(meeting).getByRole('link', { name: 'agent-1@example.com' })).toHaveAttribute(
      'href',
      'mailto:agent-1@example.com',
    )
  })

  it('opens links in a new tab', async () => {
    const windowOpenSpy = vi.spyOn(window, 'open').mockImplementation(() => null)

    mockCalendarIcsFileEventsQuery({ calendarIcsFileEvents: [meetingEvent] })

    // With the real transition the loader mounts the list two frames after the result arrives,
    //   so this only passes when the handlers are attached after that.
    const wrapper = renderComponent(CommonCalendarPreviewFlyout, {
      ...renderOptions,
      global: { stubs: { teleport: true, transition: false } },
    })

    await wrapper.events.click(
      await wrapper.findByRole('link', { name: 'https://meet.example.com/zammad' }),
    )

    expect(windowOpenSpy).toHaveBeenCalledWith(
      'https://meet.example.com/zammad',
      '_blank',
      'noopener,noreferrer',
    )

    windowOpenSpy.mockRestore()
  })

  it('renders markup in the description as text', async () => {
    const wrapper = await renderCommonCalendarPreviewFlyout([
      {
        ...meetingEvent,
        description: '<b>Bold</b> text and <script>alert(1)</script>',
      },
    ])

    expect(wrapper.getByText('<b>Bold</b> text and <script>alert(1)</script>')).toBeInTheDocument()

    expect(wrapper.container.querySelector('b')).not.toBeInTheDocument()
    expect(wrapper.container.querySelector('script')).not.toBeInTheDocument()
  })

  it('omits attributes without a value', async () => {
    const wrapper = await renderCommonCalendarPreviewFlyout()

    const [, lunch] = wrapper.getAllByRole('article')

    expect(within(lunch).getByRole('heading', { name: 'Lunch' })).toBeInTheDocument()
    expect(within(lunch).getByText('Start date')).toBeInTheDocument()
    expect(within(lunch).getByText('End date')).toBeInTheDocument()

    expect(within(lunch).queryByText('Location')).not.toBeInTheDocument()
    expect(within(lunch).queryByText('Organizer')).not.toBeInTheDocument()
    expect(within(lunch).queryByText('Attendees')).not.toBeInTheDocument()
    expect(within(lunch).queryByText('Description')).not.toBeInTheDocument()
  })

  it('shows a warning when the file contains no events', async () => {
    const wrapper = await renderCommonCalendarPreviewFlyout([])

    expect(wrapper.getByRole('alert')).toHaveTextContent(
      'No events can be shown because the calendar file does not contain any.',
    )

    expect(wrapper.queryByRole('article')).not.toBeInTheDocument()
  })

  it('shows only the error notification when the file cannot be parsed', async () => {
    mockCalendarIcsFileEventsQueryError('Failed to parse "notadate" - invalid date', {
      type: GraphQLErrorTypes.UnknownError,
    })

    const wrapper = renderComponent(CommonCalendarPreviewFlyout, renderOptions)

    await vi.waitFor(() =>
      expect(useNotifications().notifications.value.at(-1)).toMatchObject({ type: 'error' }),
    )

    expect(
      wrapper.queryByText('No events can be shown because the calendar file does not contain any.'),
    ).not.toBeInTheDocument()
  })

  it('shows a skeleton while the events are loading', async () => {
    mockCalendarIcsFileEventsQuery({ calendarIcsFileEvents: [meetingEvent] })

    const wrapper = renderComponent(CommonCalendarPreviewFlyout, renderOptions)

    expect(wrapper.getAllByRole('progressbar', { name: 'Content loader' }).length).toBeGreaterThan(
      0,
    )

    await waitForNextTick()

    expect(wrapper.queryByRole('progressbar')).not.toBeInTheDocument()
    expect(wrapper.getByRole('heading', { name: 'Zammad Helpdesk Meeting' })).toBeInTheDocument()
  })

  it('supports downloading calendar', async () => {
    const wrapper = await renderCommonCalendarPreviewFlyout()

    await wrapper.events.click(
      wrapper.getByRole('button', {
        name: 'Download',
      }),
    )

    expect(openExternalLinkMock).toHaveBeenCalledWith(
      '/api/attachments/1?disposition=attachment',
      '_blank',
      'calendar.ics',
    )
  })
})
