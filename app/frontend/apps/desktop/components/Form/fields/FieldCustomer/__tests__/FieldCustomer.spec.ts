// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import { getByRole, waitFor } from '@testing-library/vue'

import { getByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'

import {
  mockAutocompleteSearchGenericQuery,
  waitForAutocompleteSearchGenericQueryCalls,
} from '#shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/generic.mocks.ts'
import { i18n } from '#shared/i18n.ts'

import { testOptions } from '#desktop/components/Form/fields/FieldCustomer/__tests__/support/testOptions.ts'

const wrapperParameters = {
  form: true,
  formField: true,
  router: true,
  dialog: true,
  store: true,
}

const testProps = {
  type: 'customer',
  label: 'Select…',
}

describe('Form - Field - Customer - Features', () => {
  it('supports adding and removing of new email addresses', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
        clearable: true,
      },
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()

    mockAutocompleteSearchGenericQuery({
      autocompleteSearchGeneric: [],
    })

    expect(
      wrapper.queryByText('Start typing to search or enter an email address…'),
    ).toBeInTheDocument()

    await wrapper.events.type(filterElement, 'foo')

    await waitForAutocompleteSearchGenericQueryCalls()

    expect(
      wrapper.queryByRole('button', { name: 'add new email address' }),
    ).not.toBeInTheDocument()

    expect(wrapper.getByRole('option')).toHaveTextContent('Loading…')

    await wrapper.events.type(filterElement, '@bar.tld')

    await waitForAutocompleteSearchGenericQueryCalls()

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'add new email address' }),
    )

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toEqual('foo@bar.tld')

    expect(wrapper.queryByRole('menu')).not.toBeInTheDocument()

    expect(wrapper.getByRole('listitem')).toHaveTextContent('foo@bar.tld')

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.getByIconName('check2')).toBeInTheDocument()

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)

    expect(selectOptions[0]).toHaveTextContent('foo@bar.tld')

    await wrapper.events.keyboard('{Escape}')

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Clear Selection' }),
    )

    expect(emittedInput[1][0]).toBeNull()

    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()
  })
})

describe('Form - Field - Customer - Query', () => {
  it('fetches remote options via GraphQL query', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()

    expect(
      wrapper.queryByText('Start typing to search or enter an email address…'),
    ).toBeInTheDocument()

    mockAutocompleteSearchGenericQuery({
      autocompleteSearchGeneric: testOptions,
    })

    await wrapper.events.type(filterElement, 'zammad')

    await waitForAutocompleteSearchGenericQueryCalls()

    expect(
      wrapper.queryByText('Start typing to search or enter an email address…'),
    ).not.toBeInTheDocument()

    let selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(2)

    expect(selectOptions[0]).toHaveTextContent(
      `${testOptions[0].label} – ${testOptions[0].heading}`,
    )

    expect(selectOptions[1]).toHaveTextContent(
      `${testOptions[1].label} – ${i18n.t(testOptions[1].heading!, ...testOptions[1].headingPlaceholder!)}`,
    )

    expect(getByIconName(selectOptions[1], 'buildings')).toBeInTheDocument()

    const button = getByRole(selectOptions[1], 'button', {
      name: 'Has submenu',
    })

    await wrapper.events.click(button)

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)

    expect(selectOptions[0]).toHaveTextContent(
      `${testOptions[0].label} – ${testOptions[0].heading}`,
    )

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Back to previous page' }),
    )

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(2)
  })

  it('replaces local options with selection', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    mockAutocompleteSearchGenericQuery({
      autocompleteSearchGeneric: testOptions,
    })

    await wrapper.events.type(filterElement, 'zammad')

    await waitForAutocompleteSearchGenericQueryCalls()

    wrapper.events.click(wrapper.getAllByRole('option')[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(testOptions[0].value)

    expect(wrapper.queryByRole('menu')).not.toBeInTheDocument()

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[0].label,
    )

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.getByIconName('check2')).toBeInTheDocument()

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)

    expect(selectOptions[0]).toHaveTextContent(
      `${testOptions[0].label} – ${testOptions[0].heading}`,
    )
  })
})
