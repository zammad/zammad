// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import renderComponent from '#tests/support/components/renderComponent.ts'

const fn = vi.fn()
describe('CommonActionMenu', () => {
  let view: ReturnType<typeof renderComponent>

  const actions = [
    {
      key: 'delete-foo',
      label: 'Delete Foo',
      icon: 'trash3',
      onClick: ({ id }: { id: string }) => {
        fn(id)
      },
    },
    {
      key: 'change-foo',
      label: 'Change Foo',
      icon: 'person-gear',
      onClick: ({ id }: { id: string }) => {
        fn(id)
      },
    },
  ]

  beforeEach(() => {
    view = renderComponent(CommonActionMenu, {
      props: {
        entity: {
          id: 'foo-test-action',
        },
        actions,
      },
    })
  })

  it('shows action menu button by default', () => {
    expect(view.getByIconName('three-dots-vertical')).toBeInTheDocument()
  })

  it('calls onClick handler when action is clicked', async () => {
    await view.events.click(view.getByIconName('three-dots-vertical'))

    expect(view.getByIconName('trash3')).toBeInTheDocument()
    expect(view.getByIconName('person-gear')).toBeInTheDocument()

    await view.events.click(view.getByText('Change Foo'))

    expect(fn).toHaveBeenCalledWith('foo-test-action')
  })

  it('finds corresponding a11y controls', async () => {
    const id = view
      .getByLabelText('Action menu button')
      .getAttribute('aria-controls')

    await view.events.click(view.getByIconName('three-dots-vertical'))

    const popover = document.getElementById(id as string)

    expect(popover?.getAttribute('id')).toEqual(id)
  })

  describe('single action mode', () => {
    beforeEach(async () => {
      await view.rerender({
        actions: [actions[0]],
      })
    })

    it('adds aria label on single action button', () => {
      expect(view.getByLabelText('Delete Foo')).toBeInTheDocument()
    })

    it('supports single action mode', () => {
      expect(
        view.queryByIconName('three-dots-vertical'),
      ).not.toBeInTheDocument()

      expect(view.getByIconName('trash3')).toBeInTheDocument()
    })

    it('calls onClick handler when action is clicked', async () => {
      await view.events.click(view.getByIconName('trash3'))

      expect(fn).toHaveBeenCalledWith('foo-test-action')
    })

    it('renders single action if prop is set', async () => {
      await view.rerender({
        noSingleActionMode: true,
      })

      expect(view.queryByIconName('trash3')).not.toBeInTheDocument()

      await view.events.click(view.getByIconName('three-dots-vertical'))

      expect(view.getByIconName('trash3')).toBeInTheDocument()
    })
  })
})
