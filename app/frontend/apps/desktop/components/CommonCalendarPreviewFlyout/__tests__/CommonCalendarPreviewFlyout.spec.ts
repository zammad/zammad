// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockCalendarIcsFileEventsQuery } from '#desktop/entities/calendar/ics-file/graphql/queries/events.mocks.ts'

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

const { default: openExternalLinkMock } = await import(
  '#shared/utils/openExternalLink.ts'
)

const renderCommonCalendarPreviewFlyout = async (
  props: Record<string, unknown> = {},
  options: any = {},
) => {
  const result = renderComponent(CommonCalendarPreviewFlyout, {
    props: {
      fileId: convertToGraphQLId('Store', 1),
      fileType: 'text/calendar',
      fileName: 'calendar.ics',
      ...props,
    },
    ...options,
    router: true,
    form: true,
    global: {
      stubs: {
        teleport: true,
      },
    },
  })

  await waitForNextTick()

  return result
}

describe('TicketSidebarSharedDraftFlyout.vue', () => {
  beforeAll(() => {
    mockApplicationConfig({
      api_path: '/api',
    })

    mockCalendarIcsFileEventsQuery({
      calendarIcsFileEvents: [
        {
          __typename: 'CalendarIcsFileEvent',
          title: 'event 1',
          location: 'location 1',
          startDate: '2024-08-22T12:00:00:00+00:00',
          endDate: '2024-08-22T13:00:00:00+00:00',
        },
        {
          __typename: 'CalendarIcsFileEvent',
          title: 'event 2',
          location: 'location 2',
          startDate: '2024-08-22T14:00:00:00+00:00',
          endDate: '2024-08-22T15:00:00:00+00:00',
        },
        {
          __typename: 'CalendarIcsFileEvent',
          title: 'event 3',
          location: 'location 3',
          startDate: '2024-08-22T16:00:00:00+00:00',
          endDate: '2024-08-22T17:00:00:00+00:00',
        },
      ],
    })
  })

  it('renders calendar preview', async () => {
    const wrapper = await renderCommonCalendarPreviewFlyout()

    expect(
      wrapper.getByRole('complementary', {
        name: 'Preview Calendar',
      }),
    ).toBeInTheDocument()

    expect(
      wrapper.getByRole('heading', { name: 'Preview Calendar' }),
    ).toBeInTheDocument()

    expect(wrapper.getByText('event 1')).toBeInTheDocument()
    expect(wrapper.getByText('location 1')).toBeInTheDocument()
    expect(wrapper.getByText('2024-08-22 12:00')).toBeInTheDocument()
    expect(wrapper.getByText('2024-08-22 13:00')).toBeInTheDocument()

    expect(wrapper.getByText('event 2')).toBeInTheDocument()
    expect(wrapper.getByText('location 2')).toBeInTheDocument()
    expect(wrapper.getByText('2024-08-22 14:00')).toBeInTheDocument()
    expect(wrapper.getByText('2024-08-22 15:00')).toBeInTheDocument()

    expect(wrapper.getByText('event 3')).toBeInTheDocument()
    expect(wrapper.getByText('location 3')).toBeInTheDocument()
    expect(wrapper.getByText('2024-08-22 16:00')).toBeInTheDocument()
    expect(wrapper.getByText('2024-08-22 17:00')).toBeInTheDocument()
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
