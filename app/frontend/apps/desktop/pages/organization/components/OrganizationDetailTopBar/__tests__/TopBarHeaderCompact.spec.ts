// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { ref } from 'vue'

import { generateObjectData } from '#tests/graphql/builders/index.ts'
import { renderComponent } from '#tests/support/components/index.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TopBarHeaderCompact from '#desktop/pages/organization/components/OrganizationDetailTopBar/TopBarHeaderCompact.vue'
import type { DetailViewActionPlugin } from '#desktop/types/actions.ts'

const copyOrganizationDisplayNameToClipboard = vi.fn()
const topLevelActions = ref<DetailViewActionPlugin[]>([])
const secondLevelActions = ref<DetailViewActionPlugin[]>([])

vi.mock(
  '#desktop/pages/organization/components/OrganizationDetailTopBar/useTopBarHeader.ts',
  () => ({
    useTopBarHeader: () => ({
      copyOrganizationDisplayNameToClipboard,
      allowedTopLevelActions: topLevelActions,
      secondLevelActions,
    }),
  }),
)

const organization = generateObjectData('Organization', {
  id: convertToGraphQLId('Organization', 2),
  internalId: 2,
  name: 'Zammad Foundation',
  vip: false,
})

const renderTopBarHeaderCompact = (organizationDisplayName = 'Zammad Foundation') =>
  renderComponent(TopBarHeaderCompact, {
    props: { organization, organizationDisplayName },
    router: true,
  })

describe('TopBarHeaderCompact', () => {
  beforeEach(() => {
    copyOrganizationDisplayNameToClipboard.mockReset()
    topLevelActions.value = []
    secondLevelActions.value = []
  })

  it('shows the organization info', () => {
    const view = renderTopBarHeaderCompact()

    expect(view.getByRole('img', { name: 'Avatar (Zammad Foundation)' })).toBeInTheDocument()
  })

  it('copies the organization display name to clipboard when clicked', async () => {
    const view = renderTopBarHeaderCompact()

    await view.events.click(view.getByRole('button', { name: 'Copy organization display name' }))

    expect(copyOrganizationDisplayNameToClipboard).toHaveBeenCalled()
  })

  it('renders top-level actions as buttons and triggers them with the organization and router', async () => {
    const onClick = vi.fn()
    topLevelActions.value = [
      {
        key: 'new-user',
        label: 'New user',
        icon: 'plus-square-fill',
        order: 200,
        topLevel: true,
        onClick,
      },
    ]

    const view = renderTopBarHeaderCompact()

    await view.events.click(view.getByRole('button', { name: 'New user' }))

    expect(onClick).toHaveBeenCalledWith(organization, expect.anything())
  })

  it('renders second-level actions inside the action menu', async () => {
    const onClick = vi.fn()
    secondLevelActions.value = [
      {
        key: 'edit-organization',
        label: 'Edit',
        icon: 'pencil',
        order: 100,
        topLevel: false,
        onClick,
      },
    ]

    const view = renderTopBarHeaderCompact()

    await view.events.click(view.getByRole('button', { name: 'Additional actions' }))

    const menu = await view.findByRole('menu')

    await view.events.click(within(menu).getByText('Edit'))

    expect(onClick).toHaveBeenCalledWith(organization)
  })
})
