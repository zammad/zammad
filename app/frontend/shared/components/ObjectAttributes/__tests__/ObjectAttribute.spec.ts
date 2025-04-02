// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { keyBy } from 'lodash-es'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { i18n } from '#shared/i18n.ts'

import ObjectAttribute from '../ObjectAttribute.vue'

import attributes from './attributes.json'

vi.hoisted(() => {
  vi.setSystemTime('2021-04-09T10:11:12Z')
})

const attributesByKey = keyBy(attributes, 'name')

const object = {
  login: 'some_object',
  address: 'Berlin\nStreet\nHouse',
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

describe('common object attributes interface', () => {
  beforeEach(() => {
    mockApplicationConfig({
      pretty_date_format: 'absolute',
    })
  })

  test('renders all available attributes', () => {
    i18n.setTranslationMap(
      new Map([
        ['FORMAT_DATE', 'dd/mm/yyyy'],
        ['FORMAT_DATETIME', 'dd/mm/yyyy HH:MM'],
      ]),
    )

    const view = renderComponent(ObjectAttribute, {
      props: {
        object,
        attribute: attributesByKey.login,
      },
      router: true,
      store: true,
    })

    expect(view.getByText(object.login)).toBeInTheDocument()
  })

  test('show dash for empty fields', () => {
    const view = renderComponent(ObjectAttribute, {
      props: {
        object: {
          login: '',
        },
        attribute: attributesByKey.login,
      },
    })

    expect(view.getByText('-')).toBeInTheDocument()
  })

  it('translates translatable', () => {
    const translatable = (attr: any) => ({
      ...attr,
      dataOption: {
        ...attr.dataOption,
        translate: true,
      },
    })

    i18n.setTranslationMap(new Map([['Display1', 'llave1']]))

    const view = renderComponent(ObjectAttribute, {
      props: {
        object,
        attribute: translatable(attributesByKey.single_select),
      },
      router: true,
    })

    expect(view.getByText('llave1')).toBeInTheDocument()
  })

  it('renders links', () => {
    const view = renderComponent(ObjectAttribute, {
      props: {
        object,
        attribute: attributesByKey.integer_field,
      },
      router: true,
    })

    expect(view.getByRole('link', { name: '600' })).toHaveAttribute(
      'href',
      'https://integer.com/rendered',
    )
  })

  it('renders user relation', () => {
    const view = renderComponent(ObjectAttribute, {
      props: {
        object: {
          customer: {
            fullname: 'John Doe',
          },
        },
        attribute: {
          name: 'customer_id',
          dataType: 'user_autocompletion',
          dataOption: {
            relation: 'User',
            belongs_to: 'customer',
          },
        },
      },
      router: true,
    })

    expect(view.getByText('John Doe')).toBeInTheDocument()
  })

  it('renders user secondary organizations', () => {
    const view = renderComponent(ObjectAttribute, {
      props: {
        object: {
          secondaryOrganizations: {
            edges: [
              {
                node: {
                  name: 'Example',
                },
              },
              {
                node: {
                  name: 'Test',
                },
              },
            ],
            totalCount: 1,
          },
        },
        attribute: {
          name: 'organization_ids',
          dataType: 'autocompletion_ajax',
          dataOption: {
            relation: 'Organization',
            belongs_to: 'secondaryOrganizations',
          },
        },
      },
      router: true,
    })

    expect(view.getByText('Example, Test')).toBeInTheDocument()
  })

  it('renders textarea in table mode', () => {
    const view = renderComponent(ObjectAttribute, {
      props: {
        attribute: attributesByKey.address,
        object,
        mode: 'table',
      },
      router: true,
    })

    expect(view.getByText('Berlin Street House')).toBeInTheDocument()
  })

  it('renders textarea in view mode', () => {
    const view = renderComponent(ObjectAttribute, {
      props: {
        attribute: attributesByKey.address,
        object,
      },
      router: true,
    })

    expect(view.getByText('Berlin')).toHaveTextContent(/^Berlin$/)
    expect(view.getByText('Street')).toHaveTextContent(/^Street$/)
    expect(view.getByText('House')).toHaveTextContent(/^House$/)
  })
})
