// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { getAllByRole, getByRole } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'

import TimeAccountingFlyout from '../TimeAccountingFlyout.vue'

const renderTimeAccountingFlyout = async () => {
  const result = renderComponent(TimeAccountingFlyout, {
    form: true,
    global: {
      stubs: {
        teleport: true,
      },
    },
  })

  await getNode('ticket-time-accounting')?.settled

  await waitForNextTick()

  return result
}

describe('TimeAccountingFlyout.vue', () => {
  beforeEach(() => {
    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          accounted_time_type_id: {
            value: 1,
            options: [
              {
                value: 1,
                label: 'test type 1',
              },
              {
                value: 2,
                label: 'test type 2',
              },
              {
                value: 3,
                label: 'test type 3',
              },
            ],
          },
        },
      },
    })
  })

  it('renders time accounting flyout', async () => {
    const wrapper = await renderTimeAccountingFlyout()

    expect(
      wrapper.getByRole('complementary', {
        name: 'Time Accounting',
      }),
    ).toBeInTheDocument()

    expect(
      wrapper.getByRole('heading', { name: 'Time Accounting' }),
    ).toBeInTheDocument()

    expect(wrapper.getByLabelText('Accounted Time')).toBeInTheDocument()

    expect(wrapper.queryByText('hour(s)')).not.toBeInTheDocument()
    expect(wrapper.queryByLabelText('Activity Type')).not.toBeInTheDocument()

    expect(wrapper.getByRole('button', { name: 'Skip' })).toBeInTheDocument()

    expect(
      wrapper.getByRole('button', { name: 'Account Time' }),
    ).toBeInTheDocument()
  })

  it('can submit time accounting data', async () => {
    const wrapper = await renderTimeAccountingFlyout()

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Account Time' }),
    )

    const input = wrapper.getByLabelText('Accounted Time')

    expect(input).toBeDescribedBy('This field is required.')

    await wrapper.events.type(input, 'foo')

    await getNode('timeUnit')?.settled

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Account Time' }),
    )

    expect(input).toBeDescribedBy('This field must contain a number.')

    await wrapper.events.clear(input)
    await wrapper.events.type(input, '-1.5')

    await getNode('timeUnit')?.settled

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Account Time' }),
    )

    expect(wrapper.emitted('account-time')[0]).toEqual([
      {
        time_unit: '-1.5',
      },
    ])
  })

  it('can skip time accounting', async () => {
    const wrapper = await renderTimeAccountingFlyout()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Skip' }))

    expect(wrapper.emitted('skip')).toHaveLength(1)
  })

  it('supports displaying time accounting unit', async () => {
    mockApplicationConfig({
      time_accounting_unit: 'hour',
    })

    const wrapper = await renderTimeAccountingFlyout()

    expect(wrapper.queryByText('hour(s)')).toBeInTheDocument()
  })

  it('supports optional time accounting type selection', async () => {
    mockApplicationConfig({
      time_accounting_types: true,
    })

    const wrapper = await renderTimeAccountingFlyout()

    const select = wrapper.getByLabelText('Activity Type')

    // Default value set by form updater.
    expect(getNode('accountedTimeTypeId')?.value).toBe(1)

    await wrapper.events.click(select)

    const listbox = wrapper.getByRole('listbox')

    await wrapper.events.click(getAllByRole(listbox, 'option')[1])

    await wrapper.events.type(wrapper.getByLabelText('Accounted Time'), '0')

    await getNode('timeUnit')?.settled

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Account Time' }),
    )

    expect(wrapper.emitted('account-time')[0]).toEqual([
      {
        time_unit: '0',
        accounted_time_type_id: 2,
      },
    ])

    await wrapper.events.click(
      getByRole(select, 'button', { name: 'Clear Selection' }),
    )

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Account Time' }),
    )

    expect(wrapper.emitted('account-time')[1]).toEqual([
      {
        time_unit: '0',
        accounted_time_type_id: null,
      },
    ])
  })

  it.todo('should autofocus accounted time on mounted', async () => {
    const wrapper = await renderTimeAccountingFlyout()

    await waitForNextTick()

    // :TODO in test env it does not focus the input but the button? Investigate.
    expect(
      // await wrapper.findByPlaceholderText('Enter the time you want to record'),
      wrapper.getByPlaceholderText('Enter the time you want to record'),
    ).toHaveFocus()
  })
})
