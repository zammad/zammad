// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

vi.setSystemTime('2021-04-09T10:11:12Z')

import { i18n } from '@shared/i18n'
import { getByRole } from '@testing-library/vue'
import { renderComponent } from '@tests/support/components'
import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'
import { mockPermissions } from '@tests/support/mock-permissions'
import { flushPromises } from '@vue/test-utils'
import { keyBy } from 'lodash-es'
import CommonObjectAttributes from '../CommonObjectAttributes.vue'
import attributes from './attributes.json'

const attributesByKey = keyBy(attributes, 'name')

describe('common object attributes interface', () => {
  test('renders all available attributes', () => {
    mockPermissions(['admin.user', 'ticket.agent'])

    const object = {
      login: 'some_object',
      address: 'Berlin, Street, House',
      vip: true,
      note: 'note',
      active: true,
      invisible: 'invisible',
      objectAttributeValues: [
        {
          attribute: attributesByKey.date_attribute,
          value: '2022-08-19',
          __typename: 'ObjectAttributeValue',
        },
        {
          attribute: attributesByKey.textarea_field,
          value: 'textarea text',
        },
        {
          attribute: attributesByKey.integer_field,
          value: 600,
        },
        {
          attribute: attributesByKey.date_time_field,
          value: '2022-08-11T05:00:00.000Z',
        },
        {
          attribute: attributesByKey.single_select,
          value: 'key1',
        },
        {
          attribute: attributesByKey.multi_select_field,
          value: ['key1', 'key2'],
        },
        {
          attribute: attributesByKey.single_tree_select,
          value: 'key1::key1_child1',
        },
        {
          attribute: attributesByKey.multi_tree_select,
          value: ['key1', 'key2', 'key2::key2_child1'],
        },
        {
          attribute: attributesByKey.some_url,
          value: 'https://url.com',
        },
        {
          attribute: attributesByKey.some_email,
          value: 'email@email.com',
        },
        {
          attribute: attributesByKey.phone,
          value: '+49 123456789',
        },
      ],
    }

    i18n.setTranslationMap(
      new Map([
        ['FORMAT_DATE', 'dd/mm/yyyy'],
        ['FORMAT_DATETIME', 'dd/mm/yyyy HH:MM'],
      ]),
    )

    const view = renderComponent(CommonObjectAttributes, {
      props: {
        object,
        attributes,
      },
      router: true,
      store: true,
    })

    const getRegion = (name: string) => view.getByRole('region', { name })

    expect(getRegion('Login')).toHaveTextContent(object.login)
    expect(getRegion('Address')).toHaveTextContent(object.address)
    expect(getRegion('VIP')).toHaveTextContent('yes')
    expect(getRegion('Note')).toHaveTextContent(object.note)
    expect(getRegion('Active')).toHaveTextContent('yes')

    expect(getRegion('Date Attribute')).toHaveTextContent(/19\/08\/2022$/)
    expect(getRegion('Textarea Field')).toHaveTextContent('textarea text')
    expect(getRegion('Integer Field')).toHaveTextContent('600')
    expect(getRegion('DateTime Field')).toHaveTextContent('11/08/2022 05:00')
    expect(getRegion('Single Select Field')).toHaveTextContent('Display1')
    expect(getRegion('Multi Select Field')).toHaveTextContent(
      'Display1, Display2',
    )
    expect(getRegion('Single Tree Select Field')).toHaveTextContent(
      'key1::key1_child1',
    )
    expect(getRegion('Multi Tree Select Field')).toHaveTextContent(
      'key1, key2, key2::key2_child1',
    )

    expect(
      getByRole(getRegion('Phone'), 'link', { name: '+49 123456789' }),
    ).toHaveAttribute('href', 'tel:+49123456789')
    expect(
      getByRole(getRegion('Email'), 'link', { name: 'email@email.com' }),
    ).toHaveAttribute('href', 'mailto:email@email.com')
    expect(
      getByRole(getRegion('Url'), 'link', { name: 'https://url.com' }),
    ).toHaveAttribute('href', 'https://url.com')

    expect(
      view.queryByRole('region', { name: 'Invisible' }),
    ).not.toBeInTheDocument()
    expect(
      view.queryByRole('region', { name: 'Hidden Boolean' }),
    ).not.toBeInTheDocument()
  })

  test('hides attributes without permission', () => {
    mockPermissions([])

    const object = {
      active: true,
    }
    const view = renderComponent(CommonObjectAttributes, {
      props: {
        object,
        attributes: [attributesByKey.active],
      },
    })

    expect(view.queryAllByRole('region')).toHaveLength(0)
  })

  test("don't show name", () => {
    const object = {
      name: 'some_object',
    }
    const view = renderComponent(CommonObjectAttributes, {
      props: {
        object,
        attributes: [{ ...attributesByKey.login, name: 'name' }],
      },
    })

    expect(view.queryAllByRole('region')).toHaveLength(0)
  })

  test("don't show empty fields", () => {
    const object = {
      login: '',
      objectAttributesValues: [
        {
          attribute: attributesByKey.integer_field,
          value: 0,
        },
        {
          attribute: attributesByKey.multi_select_field,
          value: [],
        },
      ],
    }
    const view = renderComponent(CommonObjectAttributes, {
      props: {
        object,
        attributes: [attributesByKey.login],
      },
    })

    expect(view.queryAllByRole('region')).toHaveLength(0)
  })

  test('show default, if not defined', () => {
    const object = {
      login: '',
    }
    const attribute = {
      ...attributesByKey.login,
      name: 'login',
      display: 'Login',
    }
    const view = renderComponent(CommonObjectAttributes, {
      props: {
        object,
        attributes: [
          {
            ...attribute,
            dataOption: { ...attribute.dataOption, default: 'default' },
          },
        ],
      },
    })

    expect(view.getByRole('region', { name: 'Login' })).toHaveTextContent(
      'default',
    )
  })

  it('has linktemplate link, even for tel/email', () => {
    const object = {
      phone: '+49 123456789',
    }

    const view = renderComponent(CommonObjectAttributes, {
      props: {
        object,
        attributes: [
          {
            ...attributesByKey.phone,
            dataOption: {
              ...attributesByKey.phone.dataOption,
              linktemplate: 'https://link.com',
            },
          },
        ],
      },
    })

    const phoneRegion = view.getByRole('region', { name: 'Phone' })
    const phoneLink = getByRole(phoneRegion, 'link', {
      name: '+49 123456789',
    })

    expect(phoneLink).toHaveAttribute('href', 'https://link.com')
  })

  it('translates translatable', () => {
    mockPermissions(['admin.user', 'ticket.agent'])

    const object = {
      vip: true,
      single_select: 'key1',
      multi_select_field: ['key1', 'key2'],
      single_tree_select: 'key1::key1_child1',
      multi_tree_select: ['key1', 'key1::key1_child1'],
    }

    const translatable = (attr: any) => ({
      ...attr,
      dataOption: {
        ...attr.dataOption,
        translate: true,
      },
    })

    const attributes = [
      translatable(attributesByKey.vip),
      translatable(attributesByKey.single_select),
      translatable(attributesByKey.multi_select_field),
      translatable(attributesByKey.single_tree_select),
      translatable(attributesByKey.multi_tree_select),
    ]

    i18n.setTranslationMap(
      new Map([
        ['yes', 'sí'],
        ['Display1', 'Monitor1'],
        ['Display2', 'Monitor2'],
        ['key1', 'llave1'],
        ['key2', 'llave2'],
        ['key1_child1', 'llave1_niño1'],
      ]),
    )

    const view = renderComponent(CommonObjectAttributes, {
      props: {
        object,
        attributes,
      },
      router: true,
    })

    const getRegion = (name: string) => view.getByRole('region', { name })

    const vip = getRegion('VIP')
    const singleSelect = getRegion('Single Select Field')
    const multiSelect = getRegion('Multi Select Field')
    const singleTreeSelect = getRegion('Single Tree Select Field')
    const multiTreeSelect = getRegion('Multi Tree Select Field')

    expect(vip).toHaveTextContent('sí')
    expect(singleSelect).toHaveTextContent('Monitor1')
    expect(multiSelect).toHaveTextContent('Monitor1, Monitor2')
    expect(singleTreeSelect).toHaveTextContent('llave1::llave1_niño1')
    expect(multiTreeSelect).toHaveTextContent('llave1, llave1::llave1_niño1')
  })

  it('renders different dates', async () => {
    const object = {
      now: '2021-04-09T10:11:12Z',
      past: '2021-02-09T10:11:12Z',
      future: '2021-10-09T10:11:12Z',
    }

    const attributes = [
      { ...attributesByKey.date_time_field, name: 'now', display: 'now' },
      { ...attributesByKey.date_time_field, name: 'past', display: 'past' },
      { ...attributesByKey.date_time_field, name: 'future', display: 'future' },
    ]

    const view = renderComponent(CommonObjectAttributes, {
      props: {
        object,
        attributes,
      },
      router: true,
    })

    const getRegion = (time: string) => view.getByRole('region', { name: time })

    expect(getRegion('now')).toHaveTextContent('2021-04-09 10:11')
    expect(getRegion('past')).toHaveTextContent('2021-02-09 10:11')
    expect(getRegion('future')).toHaveTextContent('2021-10-09 10:11')

    mockApplicationConfig({
      pretty_date_format: 'relative',
    })

    await flushPromises()

    expect(getRegion('now')).toHaveTextContent('just now')
    expect(getRegion('past')).toHaveTextContent('1 month ago')
    expect(getRegion('future')).toHaveTextContent('in 6 months')
  })
})
