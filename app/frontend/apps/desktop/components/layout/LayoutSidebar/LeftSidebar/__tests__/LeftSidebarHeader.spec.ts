// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { useApplicationStore } from '#shared/stores/application.ts'

import LeftSidebarHeader from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader.vue'

import '#tests/graphql/builders/mocks.ts'

vi.mock('#shared/server/apollo/client.ts', () => ({
  getApolloClient: () => ({
    cache: {
      readQuery: vi.fn(),
      writeQuery: vi.fn(),
    },
  }),
}))

const renderLeftSidebarHeader = (collapsed = true, noPermission?: boolean) => {
  if (noPermission) mockPermissions([])
  else mockPermissions(['ticket.agent'])

  useApplicationStore().config.product_logo = 'logo.svg'
  useApplicationStore().config.product_name = 'Zammad'

  const searchValue = ref('')
  const searchActive = ref(false)

  const wrapper = renderComponent(LeftSidebarHeader, {
    props: { collapsed },
    vModel: {
      search: searchValue,
      searchActive,
    },
    router: true,
  })

  return { wrapper, searchValue, searchActive }
}

describe('LeftSidebarHeader', () => {
  it.each([true, false])('shows custom branding when collapsed is %s', async (collapsed) => {
    const { wrapper } = renderLeftSidebarHeader(collapsed)
    const application = useApplicationStore()
    application.config.product_logo = 'custom-logo.png'
    application.config.product_name = 'Example Helpdesk'
    await waitForNextTick()

    const logo = wrapper.getByRole('img', { name: 'Example Helpdesk' })
    expect(logo).toHaveAttribute('src', '/api/v1/system_assets/product_logo/custom-logo.png')
    expect(wrapper.queryByIconName('logo')).not.toBeInTheDocument()
    expect(wrapper.getByRole('button', { name: 'Show notifications' })).toContainElement(logo)

    application.config.product_logo = 'replacement.png'
    await waitForNextTick()
    expect(logo).toHaveAttribute('src', '/api/v1/system_assets/product_logo/replacement.png')

    application.config.product_logo = 'logo.svg'
    await waitForNextTick()
    expect(wrapper.getByIconName('logo')).toBeInTheDocument()
    expect(wrapper.queryByRole('img', { name: 'Example Helpdesk' })).not.toBeInTheDocument()
  })

  it.each(['logo.svg', '', undefined])('shows the stock icon for product_logo=%s', async (logo) => {
    const { wrapper } = renderLeftSidebarHeader()
    Object.assign(useApplicationStore().config, { product_logo: logo })
    await waitForNextTick()

    expect(wrapper.getByIconName('logo')).toBeInTheDocument()
    expect(wrapper.container.querySelector('img')).not.toBeInTheDocument()
  })

  it('shows custom branding without agent permission', async () => {
    const { wrapper } = renderLeftSidebarHeader(true, true)
    useApplicationStore().config.product_logo = 'customer-logo.png'
    await waitForNextTick()

    expect(wrapper.container.querySelector('img')).toHaveAttribute(
      'src',
      '/api/v1/system_assets/product_logo/customer-logo.png',
    )
    expect(wrapper.queryByRole('button', { name: 'Show notifications' })).not.toBeInTheDocument()
  })

  it('displays notification button if collapsed', async () => {
    const { wrapper } = renderLeftSidebarHeader()

    expect(wrapper.getByRole('button', { name: 'Show notifications' })).toBeInTheDocument()
  })

  it('displays notification button if not collapsed', async () => {
    const { wrapper } = renderLeftSidebarHeader(false)

    expect(wrapper.getByRole('button', { name: 'Show notifications' })).toBeInTheDocument()
  })

  it('hides Online Notification when search is active', async () => {
    const { wrapper } = renderLeftSidebarHeader(false)
    wrapper.getByRole('searchbox', { name: 'Search…' }).focus()
    await waitForNextTick()

    expect(wrapper.queryByRole('button', { name: 'Show notifications' })).not.toBeInTheDocument()
  })

  it('hides search field if collapsed is true', async () => {
    const { wrapper } = renderLeftSidebarHeader(true)

    expect(wrapper.queryByRole('searchbox', { name: 'Search…' })).not.toBeInTheDocument()
  })

  it('shows dummy logo when user has no agent permission (#5835)', async () => {
    const { wrapper } = renderLeftSidebarHeader(true, true)

    expect(wrapper.queryByRole('button', { name: 'Show notifications' })).not.toBeInTheDocument()
    expect(wrapper.getByIconName('logo')).toBeInTheDocument()
  })
})
