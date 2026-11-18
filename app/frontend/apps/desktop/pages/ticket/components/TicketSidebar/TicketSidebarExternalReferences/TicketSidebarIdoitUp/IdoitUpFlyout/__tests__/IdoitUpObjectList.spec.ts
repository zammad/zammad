// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
import { within } from '@testing-library/vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import IdoitUpObjectList from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarIdoitUp/IdoitUpFlyout/IdoitUpObjectList.vue'

const testItems = [
  {
    id: '00000000Test0026',
    idoitUpObjectId: '00000000Test0026',
    title: {
      link: 'http://localhost:9001/object/00000000Test0026',
      label: 'Main Building',
      openInNewTab: true,
      external: true,
    },
    type: 'Building',
    status: 'in operation',
  },
  {
    id: '00000000Test0042',
    idoitUpObjectId: '00000000Test0042',
    title: {
      link: 'http://localhost:9001/object/00000000Test0042',
      label: 'Server Room',
      openInNewTab: true,
      external: true,
    },
    type: 'Room',
    status: 'in operation',
  },
]

describe('IdoitUpObjectList', () => {
  it('renders table correctly', () => {
    const wrapper = renderComponent(IdoitUpObjectList, {
      props: {
        items: [testItems[0]],
      },
      router: true,
      form: true,
    })

    const container = wrapper.getByRole('table')

    const link = within(container).getByRole('link')

    expect(link).toHaveTextContent('Main Building')
    expect(link).toHaveAttribute('href', 'http://localhost:9001/object/00000000Test0026')
    expect(link).toHaveAttribute('target', '_blank')

    expect(container).toHaveTextContent('ID')
    expect(container).toHaveTextContent('00000000Test0026')

    expect(container).toHaveTextContent('Status')
    expect(container).toHaveTextContent('in operation')

    expect(wrapper.getByRole('cell', { name: '00000000Test0026' })).toBeInTheDocument()

    expect(wrapper.getByRole('checkbox', { name: 'Select all entries' })).toBeInTheDocument()
  })

  it('shows empty state message', () => {
    const wrapper = renderComponent(IdoitUpObjectList, {
      props: {
        items: [],
      },
    })

    expect(wrapper.getByText('No results found')).toBeInTheDocument()
  })

  it('emits checked rows on selection', async () => {
    const wrapper = renderComponent(IdoitUpObjectList, {
      props: {
        items: testItems,
      },
      router: true,
      form: true,
    })

    const rowCheckboxes = wrapper.getAllByRole('checkbox', {
      name: 'Select this entry',
    })

    await wrapper.events.click(rowCheckboxes[0])

    expect(wrapper.emitted('update:checkedRows')).toBeTruthy()

    const lastEmit = wrapper.emitted('update:checkedRows').at(-1) as unknown[][]
    expect(lastEmit[0]).toEqual(
      expect.arrayContaining([expect.objectContaining({ id: '00000000Test0026' })]),
    )
  })

  it('does not select disabled rows', async () => {
    const items = [{ ...testItems[0], disabled: true, checked: true }, testItems[1]]

    const wrapper = renderComponent(IdoitUpObjectList, {
      props: { items },
      router: true,
      form: true,
    })

    const rowCheckboxes = wrapper.getAllByRole('checkbox', {
      name: /(Des|S)elect this entry/,
    })

    expect(rowCheckboxes[0]).toBeDisabled()
    expect(rowCheckboxes[1]).not.toBeDisabled()
  })
})
