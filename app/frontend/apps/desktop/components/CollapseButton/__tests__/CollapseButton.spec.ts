// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import CollapseButton from '#desktop/components/CollapseButton/CollapseButton.vue'

describe('CollapseButton', () => {
  it.each([
    {
      isCollapsed: true,
      orientation: 'horizontal',
      inverse: false,
      icon: 'arrow-bar-right',
    },
    {
      isCollapsed: false,
      orientation: 'horizontal',
      inverse: false,
      icon: 'arrow-bar-left',
    },
    {
      isCollapsed: true,
      orientation: 'vertical',
      inverse: false,
      icon: 'arrows-expand',
    },
    {
      isCollapsed: false,
      orientation: 'vertical',
      inverse: false,
      icon: 'arrows-collapse',
    },
    {
      isCollapsed: true,
      orientation: 'horizontal',
      inverse: true,
      icon: 'arrow-bar-left',
    },
    {
      isCollapsed: false,
      orientation: 'horizontal',
      inverse: true,
      icon: 'arrow-bar-right',
    },
    {
      isCollapsed: true,
      orientation: 'vertical',
      inverse: true,
      icon: 'arrows-expand',
    },
    {
      isCollapsed: false,
      orientation: 'vertical',
      inverse: true,
      icon: 'arrows-collapse',
    },
  ])(
    'displays correct LTR icon (isCollapsed: $isCollapsed, orientation: $orientation, inverse: $inverse)',
    async ({ isCollapsed, orientation, inverse, icon }) => {
      const wrapper = renderComponent(CollapseButton, {
        props: {
          ownerId: 'test',
          isCollapsed,
          inverse,
          orientation,
        },
      })

      expect(wrapper.getByIconName(icon)).toBeInTheDocument()
    },
  )

  it.each([
    {
      isCollapsed: true,
      orientation: 'horizontal',
      inverse: false,
      icon: 'arrow-bar-left',
    },
    {
      isCollapsed: false,
      orientation: 'horizontal',
      inverse: false,
      icon: 'arrow-bar-right',
    },
    {
      isCollapsed: true,
      orientation: 'vertical',
      inverse: false,
      icon: 'arrows-expand',
    },
    {
      isCollapsed: false,
      orientation: 'vertical',
      inverse: false,
      icon: 'arrows-collapse',
    },
    {
      isCollapsed: true,
      orientation: 'horizontal',
      inverse: true,
      icon: 'arrow-bar-right',
    },
    {
      isCollapsed: false,
      orientation: 'horizontal',
      inverse: true,
      icon: 'arrow-bar-left',
    },
    {
      isCollapsed: true,
      orientation: 'vertical',
      inverse: true,
      icon: 'arrows-expand',
    },
    {
      isCollapsed: false,
      orientation: 'vertical',
      inverse: true,
      icon: 'arrows-collapse',
    },
  ])(
    'displays correct RTL icon (isCollapsed: $isCollapsed, orientation: $orientation, inverse: $inverse)',
    async ({ isCollapsed, orientation, inverse, icon }) => {
      const locale = useLocaleStore()

      locale.localeData = {
        dir: EnumTextDirection.Rtl,
      } as any

      const wrapper = renderComponent(CollapseButton, {
        props: {
          ownerId: 'test',
          isCollapsed,
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
        isCollapsed: true,
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
        group: 'sidebar',
      },
    })
    expect(wrapper.getByRole('button')).toHaveClasses([
      'transition-opacity',
      'opacity-0',
    ])
  })

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
        group: 'test',
      },
    })

    expect(wrapper.getByRole('button')).not.toHaveClasses([
      'transition-opacity',
      'opacity-0',
      'group-hover/test:opacity-100',
    ])
  })
})
