// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { waitForTicketSharedDraftStartDeleteMutationCalls } from '#shared/entities/ticket-shared-draft-start/graphql/mutations/ticketSharedDraftStartDelete.mocks.ts'
import { mockTicketSharedDraftStartSingleQuery } from '#shared/entities/ticket-shared-draft-start/graphql/queries/ticketSharedDraftStartSingle.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TicketSidebarSharedDraftFlyout from '../TicketSidebarSharedDraftFlyout.vue'

vi.hoisted(() => {
  vi.setSystemTime(new Date('2024-07-03T13:48:09Z'))
})

const waitForConfirmationMock = vi.fn().mockImplementation(() => true)

const waitForVariantConfirmationMock = vi
  .fn()
  .mockImplementation((variant) => variant === 'delete')

vi.mock('#shared/composables/useConfirmation.ts', async () => ({
  useConfirmation: () => ({
    waitForConfirmation: waitForConfirmationMock,
    waitForVariantConfirmation: waitForVariantConfirmationMock,
  }),
}))

const renderTicketSidebarSharedDraftFlyout = async (
  props: Record<string, unknown> = {},
  options: any = {},
) => {
  const result = renderComponent(TicketSidebarSharedDraftFlyout, {
    props: {
      sharedDraftId: convertToGraphQLId('Ticket::SharedDraftStart', 1),
      form: {
        formId: 'test-form',
      },
      ...props,
    },
    ...options,
    router: true,
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
  beforeEach(() => {
    mockTicketSharedDraftStartSingleQuery({
      ticketSharedDraftStartSingle: {
        id: convertToGraphQLId('Ticket:SharedDraftStart', 1),
        content: {
          body: 'foobar',
        },
        updatedBy: {
          fullname: 'Erika Mustermann',
        },
        updatedAt: '2024-07-03T13:48:09Z',
      },
    })
  })

  it('renders shared draft preview', async () => {
    const wrapper = await renderTicketSidebarSharedDraftFlyout()

    expect(
      wrapper.getByRole('complementary', {
        name: 'Preview Shared Draft',
      }),
    ).toBeInTheDocument()

    expect(
      wrapper.getByRole('heading', { name: 'Preview Shared Draft' }),
    ).toBeInTheDocument()

    expect(wrapper.getByText('Author')).toBeInTheDocument()
    expect(wrapper.getByText('Erika Mustermann')).toBeInTheDocument()
    expect(wrapper.getByText('Last changed')).toBeInTheDocument()
    expect(wrapper.getByText('just now')).toBeInTheDocument()
    expect(wrapper.getByText('Text')).toBeInTheDocument()
    expect(wrapper.getByText('foobar')).toBeInTheDocument()
  })

  it('supports applying shared draft', async () => {
    const triggerFormUpdater = vi.fn()

    const wrapper = await renderTicketSidebarSharedDraftFlyout({
      form: {
        formNode: {
          context: {
            state: {
              dirty: true,
            },
          },
        },
        triggerFormUpdater,
      },
    })

    await wrapper.events.click(
      wrapper.getByRole('button', {
        name: 'Apply',
      }),
    )

    expect(waitForConfirmationMock).toHaveBeenCalled()

    expect(triggerFormUpdater).toHaveBeenCalledWith({
      additionalParams: {
        sharedDraftStartId: convertToGraphQLId('Ticket::SharedDraftStart', 1),
      },
    })

    expect(wrapper.emitted('shared-draft-applied')).toHaveLength(1)
  })

  it('supports deleting shared draft', async () => {
    const wrapper = await renderTicketSidebarSharedDraftFlyout()

    await wrapper.events.click(
      wrapper.getByRole('button', {
        name: 'Delete',
      }),
    )

    const calls = await waitForTicketSharedDraftStartDeleteMutationCalls()

    expect(waitForVariantConfirmationMock).toHaveBeenCalled()

    expect(calls.at(-1)?.variables).toEqual({
      sharedDraftId: convertToGraphQLId('Ticket::SharedDraftStart', 1),
    })

    expect(wrapper.emitted('shared-draft-deleted')).toHaveLength(1)
  })
})
