// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import CommonAvatar from '../CommonAvatar.vue'

describe('CommonAvatar.vue', () => {
  it('renders when no props are passed', () => {
    const view = renderComponent(CommonAvatar)

    const avatar = view.getByTestId('common-avatar')

    expect(avatar).toHaveTextContent('??')
    expect(avatar).toHaveClass('size-medium')
    expect(avatar).toHaveStyle({ 'background-image': '' })
  })

  it('renders initials and chooses color based on it', async () => {
    const view = renderComponent(CommonAvatar, {
      props: { initials: 'VL' },
    })

    const avatar = view.getByTestId('common-avatar')

    expect(avatar).toHaveTextContent('VL')

    await view.rerender({ initials: 'VS' })

    expect(avatar).toHaveTextContent('VS')

    await view.rerender({ initials: '??' })

    expect(avatar).toHaveTextContent('??')
  })

  it('renders an image, if it is provided', async () => {
    const view = renderComponent(CommonAvatar, {
      props: { image: '/api/v1/users/image/123', initials: 'VL' },
    })

    const avatar = view.getByTestId('common-avatar')

    expect(
      avatar,
      "don't render initials, when image is present to not overlap it",
    ).not.toHaveTextContent('VL')
    expect(avatar).toHaveStyle({
      'background-image': 'url("/api/v1/users/image/123")',
    })

    await view.rerender({ image: 'data:image/png;base64,1' })

    expect(
      avatar,
      'renders base64 as an image instead of relying on API',
    ).toHaveStyle({
      'background-image': 'url("data:image/png;base64,1")',
    })
  })

  it('renders an icon, if provided', () => {
    const view = renderComponent(CommonAvatar, {
      props: { icon: 'mobile-facebook', initials: 'VL' },
    })

    const avatar = view.getByTestId('common-avatar')

    expect(avatar).not.toHaveTextContent('VL')
    expect(view.getByIconName('mobile-facebook')).toBeInTheDocument()
  })

  it('renders different sizes', async () => {
    const view = renderComponent(CommonAvatar)

    const avatar = view.getByTestId('common-avatar')

    expect(avatar).toHaveClass('size-medium')
    expect(avatar).not.toHaveClass('size-small')
    expect(avatar).not.toHaveClass('size-large')

    await view.rerender({ size: 'small' })

    expect(avatar).not.toHaveClass('size-medium')
    expect(avatar).toHaveClass('size-small')
    expect(avatar).not.toHaveClass('size-large')

    await view.rerender({ size: 'large' })

    expect(avatar).not.toHaveClass('size-medium')
    expect(avatar).not.toHaveClass('size-small')
    expect(avatar).toHaveClass('size-large')
  })

  it('renders vip icon', async () => {
    const view = renderComponent(CommonAvatar)
    expect(view.queryByIconName('mobile-crown')).not.toBeInTheDocument()
    await view.rerender({ vip: true })
    expect(view.getByIconName('mobile-crown')).toBeInTheDocument()
  })
})
