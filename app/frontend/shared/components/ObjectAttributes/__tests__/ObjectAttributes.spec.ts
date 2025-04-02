// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { getByRole } from '@testing-library/vue'
import { flushPromises } from '@vue/test-utils'
import { keyBy } from 'lodash-es'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { i18n } from '#shared/i18n.ts'

import ObjectAttributes from '../ObjectAttributes.vue'

import attributes from './attributes.json'

vi.hoisted(() => {
  vi.setSystemTime('2021-04-09T10:11:12Z')
})

const attributesByKey = keyBy(attributes, 'name')

describe('common object attributes interface', () => {
  beforeEach(() => {
    mockApplicationConfig({
      pretty_date_format: 'absolute',
    })
  })

  test('renders all available attributes', () => {
    mockPermissions(['admin.user', 'ticket.agent'])

    const object = {
      login: 'some_object',
      address: 'Berlin, Street, House',
      vip: true,
      note: 'note',
      active: true,
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
        {
          attribute: attributesByKey.external_attribute,
          value: { value: 1, label: 'Display External' },
        },
      ],
    }

    i18n.setTranslationMap(
      new Map([
        ['FORMAT_DATE', 'dd/mm/yyyy'],
        ['FORMAT_DATETIME', 'dd/mm/yyyy HH:MM'],
      ]),
    )

    const view = renderComponent(ObjectAttributes, {
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
      'key1 › key1_child1',
    )
    expect(getRegion('Multi Tree Select Field')).toHaveTextContent(
      'key1, key2, key2 › key2_child1',
    )
    expect(getRegion('External Attribute')).toHaveTextContent(
      'Display External',
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
      view.queryByRole('region', { name: 'Hidden Boolean' }),
    ).not.toBeInTheDocument()
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
    const view = renderComponent(ObjectAttributes, {
      props: {
        object,
        attributes: [attributesByKey.login],
      },
    })

    expect(view.queryAllByRole('region')).toHaveLength(0)
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

    const view = renderComponent(ObjectAttributes, {
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
    expect(singleTreeSelect).toHaveTextContent('llave1 › llave1_niño1')
    expect(multiTreeSelect).toHaveTextContent('llave1, llave1 › llave1_niño1')
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

    const view = renderComponent(ObjectAttributes, {
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

  it('doesnt render skipped attributes', () => {
    const object = {
      skip: 'skip',
      show: 'show',
    }

    const attributes = [
      { ...attributesByKey.address, name: 'skip', display: 'skip' },
      { ...attributesByKey.address, name: 'show', display: 'show' },
    ]

    const view = renderComponent(ObjectAttributes, {
      props: {
        object,
        attributes,
        skipAttributes: ['skip'],
      },
      router: true,
    })

    expect(view.getByRole('region', { name: 'show' })).toBeInTheDocument()
    expect(view.queryByRole('region', { name: 'skip' })).not.toBeInTheDocument()
  })

  it('renders links', () => {
    const object = {
      objectAttributeValues: [
        {
          attribute: {
            ...attributesByKey.integer_field,
            dataOption: {
              ...attributesByKey.integer_field.dataOption,
              linktemplate: 'https://integer.com/#{render}',
            },
          },
          value: 600,
          renderedLink: 'https://integer.com/rendered',
        },
        {
          attribute: attributesByKey.some_url,
          value: 'https://url.com',
        },
        {
          attribute: {
            ...attributesByKey.some_email,
            dataOption: {
              ...attributesByKey.integer_field.dataOption,
              linktemplate: 'https://email.com/#{render}',
            },
          },
          value: 'email@email.com',
          renderedLink: 'https://email.com/rendered',
        },
        {
          attribute: {
            ...attributesByKey.phone,
            dataOption: {
              ...attributesByKey.integer_field.dataOption,
              linktemplate: 'https://phone.com/#{render}',
            },
          },
          value: '+49 123456789',
          renderedLink: 'https://phone.com/rendered',
        },
      ],
    }

    const attributes = object.objectAttributeValues.map((v) => v.attribute)

    const view = renderComponent(ObjectAttributes, {
      props: {
        object,
        attributes,
        skipAttributes: ['skip'],
      },
      router: true,
    })

    const getRegion = (name: string) => view.getByRole('region', { name })

    expect(
      getByRole(getRegion('Integer Field'), 'link', { name: '600' }),
    ).toHaveAttribute('href', 'https://integer.com/rendered')
    expect(
      getByRole(getRegion('Phone'), 'link', { name: '+49 123456789' }),
    ).toHaveAttribute('href', 'https://phone.com/rendered')
    expect(
      getByRole(getRegion('Email'), 'link', { name: 'email@email.com' }),
    ).toHaveAttribute('href', 'https://email.com/rendered')
    expect(
      getByRole(getRegion('Url'), 'link', { name: 'https://url.com' }),
    ).toHaveAttribute('href', 'https://url.com')
  })
})
