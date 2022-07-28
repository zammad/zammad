// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import CommonUserAvatar, { type Props } from '../CommonUserAvatar.vue'

describe('CommonUserAvatar', () => {
  it('renders user avatar', async () => {
    const view = renderComponent(CommonUserAvatar, {
      props: <Props>{
        entity: {
          id: '123',
          firstname: 'John',
          lastname: 'Doe',
        },
      },
    })

    const avatar = view.getByTestId('common-avatar')

    expect(avatar).toHaveTextContent('JD')
    expect(avatar).toHaveClass('bg-blue')

    await view.rerender(<Props>{
      entity: {
        id: '123',
        image: '100.png',
        firstname: 'John',
        lastname: 'Doe',
      },
    })

    expect(avatar).toHaveStyle(
      'background-image: url(/api/users/image/100.png)',
    )
    expect(avatar).not.toHaveTextContent('JD')
  })

  it('renders system user', () => {
    const view = renderComponent(CommonUserAvatar, {
      props: <Props>{
        entity: {
          id: '1',
        },
      },
    })

    const avatar = view.getByTestId('common-avatar')

    expect(view.getByIconName('logo')).toBeInTheDocument()
    expect(avatar).toHaveClass('bg-white')
  })

  it('renders icon by source', async () => {
    const view = renderComponent(CommonUserAvatar, {
      props: <Props>{
        entity: {
          id: '123',
          source: 'twitter',
        },
      },
    })

    expect(view.getByIconName('twitter')).toBeInTheDocument()

    await view.rerender(<Props>{
      entity: {
        id: '123',
        source: 'facebook',
      },
    })

    expect(view.getByIconName('facebook')).toBeInTheDocument()

    await view.rerender(<Props>{
      entity: {
        id: '123',
        source: 'some-unknown-source',
      },
    })

    expect(view.queryByIconName('some-unknown-source')).not.toBeInTheDocument()
  })

  it('renders active and outOfOffice', async () => {
    const view = renderComponent(CommonUserAvatar, {
      props: <Props>{
        entity: {
          id: '123',
          active: true,
        },
      },
    })

    const avatar = view.getByTestId('common-avatar')

    expect(avatar).not.toHaveClass('grayscale')
    expect(avatar).not.toHaveClass('grayscale-[70%]')

    await view.rerender(<Props>{
      entity: {
        id: '123',
        active: false,
        outOfOffice: true,
      },
    })

    expect(avatar).toHaveClass('grayscale-[70%]')

    await view.rerender(<Props>{
      entity: {
        id: '123',
        active: false,
        outOfOffice: false,
      },
    })

    expect(avatar).toHaveClass('grayscale')
  })

  it('renders crown for vip', async () => {
    const view = renderComponent(CommonUserAvatar, {
      props: <Props>{
        entity: {
          id: '123',
          vip: true,
        },
      },
    })

    expect(view.getByIconName('crown')).toBeInTheDocument()

    await view.rerender(<Props>{
      entity: {
        id: '123',
        vip: true,
      },
      personal: true,
    })

    expect(view.queryByIconName('crown')).not.toBeInTheDocument()
  })
})
