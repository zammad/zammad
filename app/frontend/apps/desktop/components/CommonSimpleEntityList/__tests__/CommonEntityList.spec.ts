// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { describe } from 'vitest'
import { ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import {
  organizationOption,
  userOption,
} from '#desktop/components/CommonSimpleEntityList/__tests__/support/entityOptions.ts'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'

describe('CommonSimpleEntityList', () => {
  describe('Entity Types', () => {
    it('renders a list of users', async () => {
      mockPermissions(['ticket.agent'])

      const wrapper = renderComponent(CommonSimpleEntityList, {
        router: true,
        props: {
          id: 'test-id',
          type: EntityType.User,
          entity: {
            array: userOption,
            totalCount: userOption.length,
          },
        },
      })

      expect(await wrapper.findByText('Nicole Braun')).toBeInTheDocument()
      expect(wrapper.getByText('Thomas Ernst')).toBeInTheDocument()
      expect(
        wrapper.getByLabelText('Avatar (Nicole Braun)'),
      ).toBeInTheDocument()
      expect(
        wrapper.getByLabelText('Avatar (Thomas Ernst)'),
      ).toBeInTheDocument()
      expect(wrapper.getAllByTestId('common-link')).toHaveLength(3)
      expect(wrapper.getAllByTestId('common-link').at(0)).toHaveAttribute(
        'href',
        '/user/profile/2',
      )
    })

    it('renders a list of organizations', async () => {
      const wrapper = renderComponent(CommonSimpleEntityList, {
        router: true,
        props: {
          id: 'test-id',
          type: EntityType.Organization,
          entity: {
            array: organizationOption,
            totalCount: organizationOption.length,
          },
        },
      })

      expect(await wrapper.findByText('Spar')).toBeInTheDocument()
      expect(wrapper.getByText('Mercadona')).toBeInTheDocument()
      expect(wrapper.getByLabelText('Avatar (Spar)')).toBeInTheDocument()
      expect(wrapper.getByLabelText('Avatar (Mercadona)')).toBeInTheDocument()
      expect(wrapper.getAllByTestId('common-link')).toHaveLength(3)
      expect(wrapper.getAllByTestId('common-link').at(0)).toHaveAttribute(
        'href',
        '/organizations/2',
      )
    })
  })

  it('supports entity label', () => {
    const wrapper = renderComponent(CommonSimpleEntityList, {
      router: true,
      props: {
        id: 'test-id',
        label: 'Foo Label',
        type: EntityType.User,
        entity: {
          array: userOption,
          totalCount: userOption.length,
        },
      },
    })

    expect(wrapper.getByText('Foo Label')).toBeInTheDocument()
  })

  it('hides load more button if less than three entities are available', () => {
    const wrapper = renderComponent(CommonSimpleEntityList, {
      router: true,
      props: {
        id: 'test-id',
        type: EntityType.User,
        entity: {
          array: userOption,
          totalCount: userOption.length,
        },
      },
    })

    expect(
      wrapper.queryByRole('button', {
        name: /show/i,
      }),
    ).not.toBeInTheDocument()
  })

  it('emits load-more event if more than three entities are available', async () => {
    const wrapper = renderComponent(CommonSimpleEntityList, {
      router: true,
      props: {
        id: 'test-id',
        type: EntityType.User,
        entity: {
          array: userOption,
          totalCount: userOption.length + 1,
        },
      },
    })

    await wrapper.events.click(
      wrapper.getByRole('button', {
        name: 'Show 1 more',
      }),
    )

    expect(wrapper.emitted()['load-more']).toHaveLength(1)
  })

  it('displays message if list is empty', async () => {
    const wrapper = renderComponent(CommonSimpleEntityList, {
      router: true,
      props: {
        id: 'test-id',
        type: EntityType.User,
        entity: {
          array: [],
          totalCount: 0,
        },
      },
    })

    expect(wrapper.getByText('No members found')).toBeInTheDocument()
  })

  it('supports model value for the collapsed state', async () => {
    const modelValue = ref(false)

    renderComponent(CommonSimpleEntityList, {
      router: true,
      vModel: {
        modelValue,
      },
      props: {
        id: 'test-id',
        label: 'foobar',
        type: EntityType.User,
        entity: {
          array: [],
          totalCount: 0,
        },
      },
    })

    expect(document.querySelector('#test-id')).toHaveStyle('display: block')

    modelValue.value = true

    await waitForNextTick()

    expect(document.querySelector('#test-id')).toHaveStyle('display: none')
  })
})
