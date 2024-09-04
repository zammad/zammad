// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import CollapseButton from '#desktop/components/CollapseButton/CollapseButton.vue'

describe('CollapseButton', () => {
  it.each([
    {
      collapsed: true,
      orientation: 'horizontal',
      inverse: false,
      icon: 'arrow-bar-right',
    },
    {
      collapsed: false,
      orientation: 'horizontal',
      inverse: false,
      icon: 'arrow-bar-left',
    },
    {
      collapsed: true,
      orientation: 'vertical',
      inverse: false,
      icon: 'arrows-expand',
    },
    {
      collapsed: false,
      orientation: 'vertical',
      inverse: false,
      icon: 'arrows-collapse',
    },
    {
      collapsed: true,
      orientation: 'horizontal',
      inverse: true,
      icon: 'arrow-bar-left',
    },
    {
      collapsed: false,
      orientation: 'horizontal',
      inverse: true,
      icon: 'arrow-bar-right',
    },
    {
      collapsed: true,
      orientation: 'vertical',
      inverse: true,
      icon: 'arrows-expand',
    },
    {
      collapsed: false,
      orientation: 'vertical',
      inverse: true,
      icon: 'arrows-collapse',
    },
  ])(
    'displays correct LTR icon (collapsed: $collapsed, orientation: $orientation, inverse: $inverse)',
    async ({ collapsed, orientation, inverse, icon }) => {
      const wrapper = renderComponent(CollapseButton, {
        props: {
          ownerId: 'test',
          collapsed,
          inverse,
          orientation,
        },
      })

      expect(wrapper.getByIconName(icon)).toBeInTheDocument()
    },
  )

  it.each([
    {
      collapsed: true,
      orientation: 'horizontal',
      inverse: false,
      icon: 'arrow-bar-left',
    },
    {
      collapsed: false,
      orientation: 'horizontal',
      inverse: false,
      icon: 'arrow-bar-right',
    },
    {
      collapsed: true,
      orientation: 'vertical',
      inverse: false,
      icon: 'arrows-expand',
    },
    {
      collapsed: false,
      orientation: 'vertical',
      inverse: false,
      icon: 'arrows-collapse',
    },
    {
      collapsed: true,
      orientation: 'horizontal',
      inverse: true,
      icon: 'arrow-bar-right',
    },
    {
      collapsed: false,
      orientation: 'horizontal',
      inverse: true,
      icon: 'arrow-bar-left',
    },
    {
      collapsed: true,
      orientation: 'vertical',
      inverse: true,
      icon: 'arrows-expand',
    },
    {
      collapsed: false,
      orientation: 'vertical',
      inverse: true,
      icon: 'arrows-collapse',
    },
  ])(
    'displays correct RTL icon (collapsed: $collapsed, orientation: $orientation, inverse: $inverse)',
    async ({ collapsed, orientation, inverse, icon }) => {
      const locale = useLocaleStore()

      locale.localeData = {
        dir: EnumTextDirection.Rtl,
      } as any

      const wrapper = renderComponent(CollapseButton, {
        props: {
          ownerId: 'test',
          collapsed,
          inverse,
          orientation,
        },
      })

      expect(wrapper.getByIconName(icon)).toBeInTheDocument()
    },
  )

  it('emits toggle-collapse event on click', async () => {
    const wrapper = renderComponent(CollapseButton, {
      props: {
        ownerId: 'test',
        collapsed: true,
      },
    })

    await wrapper.events.click(wrapper.getByRole('button'))

    expect(wrapper.emitted('toggle-collapse')).toBeTruthy()
  })

  it('renders the button by default', () => {
    const wrapper = renderComponent(CollapseButton, {
      props: {
        ownerId: 'test',
      },
    })

    expect(wrapper.getByRole('button')).toBeInTheDocument()
  })

  it('shows only on hover for non-touch devices', () => {
    const wrapper = renderComponent(CollapseButton, {
      props: {
        ownerId: 'test',
      },
    })
    expect(wrapper.getByRole('button').parentElement).toHaveClasses([
      'opacity-0',
    ])
  })

  it.each(['tertiary-gray', 'none'])(
    'renders variant %s correctly',
    (variant) => {
      const wrapper = renderComponent(CollapseButton, {
        props: {
          variant,
          ownerId: 'test',
        },
      })
      if (variant === 'tertiary-gray') {
        expect(wrapper.getByRole('button')).toHaveClasses([
          'focus-visible:bg-blue-800',
          'active:dark:bg-blue-800',
          'focus:dark:bg-blue-800',
          'active:bg-blue-800',
          'focus:bg-blue-800',
          'hover:bg-blue-600',
          'hover:dark:bg-blue-900',
          'text-black',
          'dark:bg-gray-200',
          'dark:text-white',
        ])
      }
      expect(wrapper.getByRole('button')).toHaveClasses([])
    },
  )

  it('shows always for touch devices', () => {
    // Impersonate a touch device by mocking the corresponding media query.
    Object.defineProperty(window, 'matchMedia', {
      value: vi.fn().mockImplementation(() => ({
        matches: true,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      })),
    })

    const wrapper = renderComponent(CollapseButton, {
      props: {
        ownerId: 'test',
      },
    })

    expect(wrapper.getByRole('button')).not.toHaveClasses([
      'transition-opacity',
      'opacity-0',
      'group-hover/test:opacity-100',
    ])
  })

  it('supports custom labels for expand and collapse', async () => {
    const wrapper = renderComponent(CollapseButton, {
      props: {
        ownerId: 'test',
        collapsed: true,
        expandLabel: 'expand foo',
        collapseLabel: 'collapse foo',
      },
    })

    expect(wrapper.getByLabelText('expand foo')).toBeInTheDocument()

    await wrapper.rerender({
      collapsed: false,
    })

    expect(wrapper.getByLabelText('collapse foo')).toBeInTheDocument()
  })
})
