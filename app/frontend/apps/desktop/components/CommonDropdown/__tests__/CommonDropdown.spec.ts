// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonDropdown from '#desktop/components/CommonDropdown/CommonDropdown.vue'

const dropdownItems = [
  {
    label: 'Option 1',
    key: 'option1',
  },
  {
    label: 'Option 2',
    key: 'option2',
  },
]

describe('CommonDropdown', () => {
  it('supports displaying of dropdown with action items', async () => {
    const wrapper = renderComponent(CommonDropdown, {
      props: {
        items: dropdownItems,
        actionLabel: 'text-dropdown',
      },
    })

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'text-dropdown' }),
    )

    expect(await wrapper.findByRole('menu')).toBeInTheDocument()
    expect(wrapper.queryByRole('checkbox')).not.toBeInTheDocument()
  })

  it('emits event when dropdown item is clicked', async () => {
    const wrapper = renderComponent(CommonDropdown, {
      props: {
        items: dropdownItems,
        actionLabel: 'action-dropdown',
      },
    })

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'action-dropdown' }),
    )

    expect(await wrapper.findByRole('menu')).toBeInTheDocument()

    await wrapper.events.click(
      wrapper.getByRole('button', { name: dropdownItems[0].label }),
    )

    expect(wrapper.emitted('handle-action')).toEqual([[dropdownItems[0]]])
  })

  it('supports displaying of dropdown with select items', async () => {
    const selectedItem = dropdownItems[0]

    const wrapper = renderComponent(CommonDropdown, {
      props: {
        dropdownItems,
        items: dropdownItems,
      },
      vModel: {
        modelValue: selectedItem,
      },
    })

    expect(
      wrapper.getByRole('button', { name: selectedItem.label }),
    ).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByText(dropdownItems[0].label))

    const checkboxes = await wrapper.findAllByRole('checkbox')

    expect(checkboxes).toHaveLength(2)

    await wrapper.events.click(wrapper.getByText(dropdownItems[1].label))

    expect(
      await wrapper.findByRole('button', { name: dropdownItems[1].label }),
    ).toBeInTheDocument()
  })
})
