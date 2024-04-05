// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import CollapseButton from '#desktop/components/CollapseButton/CollapseButton.vue'
import { renderComponent } from '#tests/support/components/index.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'

describe('CollapseButton', () => {
  it.each([
    {
      isCollapsed: true,
      orientation: 'horizontal',
      icon: 'arrow-bar-right',
    },
    {
      isCollapsed: false,
      orientation: 'horizontal',
      icon: 'arrow-bar-left',
    },
    {
      isCollapsed: true,
      orientation: 'vertical',
      icon: 'arrows-expand',
    },
    {
      isCollapsed: false,
      orientation: 'vertical',
      icon: 'arrows-collapse',
    },
  ])(
    'displays correct LTR icon (isCollapsed: $isCollapsed, orientation: $orientation)',
    async ({ isCollapsed, orientation, icon }) => {
      const wrapper = renderComponent(CollapseButton, {
        props: {
          isCollapsed,
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
      icon: 'arrow-bar-left',
    },
    {
      isCollapsed: false,
      orientation: 'horizontal',
      icon: 'arrow-bar-right',
    },
    {
      isCollapsed: true,
      orientation: 'vertical',
      icon: 'arrows-expand',
    },
    {
      isCollapsed: false,
      orientation: 'vertical',
      icon: 'arrows-collapse',
    },
  ])(
    'displays correct RTL icon (isCollapsed: $isCollapsed, orientation: $orientation)',
    async ({ isCollapsed, orientation, icon }) => {
      const locale = useLocaleStore()

      locale.localeData = {
        dir: EnumTextDirection.Rtl,
      } as any

      const wrapper = renderComponent(CollapseButton, {
        props: {
          isCollapsed,
          orientation,
        },
      })

      expect(wrapper.getByIconName(icon)).toBeInTheDocument()
    },
  )

  it('emits toggle-collapse event on click', async () => {
    const wrapper = renderComponent(CollapseButton, {
      props: {
        isCollapsed: true,
      },
    })

    await wrapper.events.click(wrapper.getByRole('button'))

    expect(wrapper.emitted('toggle-collapse')).toBeTruthy()
  })

  it('renders the button by default', () => {
    const wrapper = renderComponent(CollapseButton)

    expect(wrapper.getByRole('button')).toBeInTheDocument()
  })

  it('shows only on hover for non-touch devices', () => {
    const wrapper = renderComponent(CollapseButton, {
      props: {
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
