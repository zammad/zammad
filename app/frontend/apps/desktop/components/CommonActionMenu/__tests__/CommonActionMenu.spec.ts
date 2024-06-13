// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import type { ObjectLike } from '#shared/types/utils.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

import type { Props } from '../CommonActionMenu.vue'

const fn = vi.fn()

describe('CommonActionMenu', () => {
  const actions: MenuItem[] = [
    {
      key: 'delete-foo',
      label: 'Delete Foo',
      icon: 'trash3',
      show: () => true,
      onClick: (entity?: ObjectLike) => {
        fn(entity?.id)
      },
    },
    {
      key: 'change-foo',
      label: 'Change Foo',
      icon: 'person-gear',
      show: () => true,
      onClick: (entity?: ObjectLike) => {
        fn(entity?.id)
      },
    },
  ]

  const renderActionMenu = async (
    actions: MenuItem[],
    props?: Partial<Props>,
  ) => {
    return renderComponent(CommonActionMenu, {
      props: {
        ...props,
        entity: {
          id: 'foo-test-action',
        },
        actions,
      },
    })
  }

  describe('Multiple Actions', () => {
    it('shows action menu button by default', async () => {
      const view = await renderActionMenu(actions)
      expect(view.getByIconName('three-dots-vertical')).toBeInTheDocument()
    })

    it('show not content when no item exists', async () => {
      const view = await renderActionMenu([
        {
          ...actions[0],
          show: () => false,
        },
        {
          ...actions[1],
          show: () => false,
        },
        {
          key: 'example',
          label: 'Example',
          show: () => false,
        },
      ])

      expect(
        view.queryByIconName('three-dots-vertical'),
      ).not.toBeInTheDocument()
    })

    it('calls onClick handler when action is clicked', async () => {
      const view = await renderActionMenu(actions)

      await view.events.click(view.getByIconName('three-dots-vertical'))

      expect(view.getByIconName('trash3')).toBeInTheDocument()
      expect(view.getByIconName('person-gear')).toBeInTheDocument()

      await view.events.click(view.getByText('Change Foo'))

      expect(fn).toHaveBeenCalledWith('foo-test-action')
    })

    it('finds corresponding a11y controls', async () => {
      const view = await renderActionMenu(actions)

      await view.events.click(view.getByIconName('three-dots-vertical'))
      const id = view
        .getByLabelText('Action menu button')
        .getAttribute('aria-controls')

      const popover = document.getElementById(id as string)

      expect(popover?.getAttribute('id')).toEqual(id)
    })

    it('sets a custom aria label on single action button', async () => {
      const view = await renderActionMenu(actions, {
        customMenuButtonLabel: 'Custom Action Menu Label',
      })

      await view.rerender({
        customMenuButtonLabel: 'Custom Action Menu Label',
      })

      expect(
        view.getByLabelText('Custom Action Menu Label'),
      ).toBeInTheDocument()
    })
  })

  describe('single action mode', () => {
    it('adds aria label on single action button', async () => {
      const view = await renderActionMenu([actions[0]])

      expect(view.getByLabelText('Delete Foo')).toBeInTheDocument()
    })

    it('supports single action mode', async () => {
      const view = await renderActionMenu([actions[0]])

      expect(
        view.queryByIconName('three-dots-vertical'),
      ).not.toBeInTheDocument()

      expect(view.getByIconName('trash3')).toBeInTheDocument()
    })

    it('calls onClick handler when action is clicked', async () => {
      const view = await renderActionMenu([actions[0]])

      await view.events.click(view.getByIconName('trash3'))

      expect(fn).toHaveBeenCalledWith('foo-test-action')
    })

    it('renders single action if prop is set', async () => {
      const view = await renderActionMenu([actions[0]], {
        noSingleActionMode: true,
      })

      expect(view.queryByIconName('trash3')).not.toBeInTheDocument()

      await view.events.click(view.getByIconName('three-dots-vertical'))

      expect(view.getByIconName('trash3')).toBeInTheDocument()
    })

    it('sets a custom aria label on single action', async () => {
      const view = await renderActionMenu([
        {
          key: 'delete-foo',
          label: 'Delete Foo',
          ariaLabel: 'Custom Delete Foo',
          icon: 'trash3',
          onClick: (entity?: ObjectLike) => {
            fn(entity?.id)
          },
        },
      ])

      expect(view.getByLabelText('Custom Delete Foo')).toBeInTheDocument()

      await view.rerender({
        actions: [
          {
            key: 'delete-foo',
            label: 'Delete Foo',
            ariaLabel: (entity: ObjectLike) => `label ${entity.id}`,
            icon: 'trash3',
            onClick: (entity?: ObjectLike) => {
              fn(entity?.id)
            },
          },
        ],
      })
      expect(view.getByLabelText('label foo-test-action')).toBeInTheDocument()
    })
  })
})
