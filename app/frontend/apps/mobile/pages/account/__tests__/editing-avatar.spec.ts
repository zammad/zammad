// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ExtendedRenderResult } from '@tests/support/components'
import { visitView } from '@tests/support/components/visitView'
import { mockAccount } from '@tests/support/mock-account'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { defineComponent } from 'vue'
import { AccountAvatarActiveDocument } from '../avatar/graphql/queries/active.api'
import { AccountAvatarAddDocument } from '../avatar/graphql/mutations/add.api'
import { AccountAvatarDeleteDocument } from '../avatar/graphql/mutations/delete.api'

vi.mock('vue-advanced-cropper', () => {
  const Cropper = defineComponent({
    emits: ['change'],
    mounted() {
      this.$emit('change', {
        canvas: {
          toDataURL() {
            return 'cropped image url'
          },
        },
      })
    },
    template: '<div></div>',
  })

  return {
    Cropper,
  }
})

const mockAvatarImage =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg=='

const getAvatarObject = (deletable: boolean) => {
  return {
    id: 'Z2lkOi8vemFtbWFkL0F2YXRhci8yNA',
    default: true,
    deletable,
    initial: false,
    imageFull: mockAvatarImage,
    imageResize: mockAvatarImage,
    createdAt: '2022-07-12T06:54:45Z',
    updatedAt: '2022-07-12T06:54:45Z',
  }
}

const mockActiveAvatar = async (deletable = true) => {
  mockGraphQLApi(AccountAvatarActiveDocument).willResolve({
    accountAvatarActive: getAvatarObject(deletable),
  })
}

const mockAddAvatar = async () => {
  mockGraphQLApi(AccountAvatarAddDocument).willResolve({
    accountAvatarAdd: {
      avatar: getAvatarObject(true),
      errors: null,
    },
  })
}

const mockDeleteAvatar = async () => {
  mockGraphQLApi(AccountAvatarDeleteDocument).willResolve({
    accountAvatarDelete: {
      success: true,
      errors: null,
    },
  })
}

const checkShownAvatar = async (view: ExtendedRenderResult, image: string) => {
  const waitForAvatar = await view.findByTestId('common-avatar')

  expect(waitForAvatar).toHaveStyle({
    'background-image': image,
  })
}

const uploadFile = async (view: ExtendedRenderResult, testFlag: string) => {
  expect(view.queryByText('Save')).not.toBeInTheDocument()

  const file = new File([], 'test.jpg', { type: 'image/jpeg' })
  await view.events.upload(view.getByTestId(testFlag), file)

  const saveButton = await view.findByText('Save')
  expect(saveButton).toBeVisible()
  await view.events.click(saveButton)
}

const removeAvatar = async (view: ExtendedRenderResult) => {
  await view.events.click(view.getByText('Delete'))
  await view.findByText('Delete avatar')
  await view.events.click(view.getByText('Delete avatar'))
  await checkShownAvatar(view, '')
}

describe('editing avatar', () => {
  beforeEach(() => {
    mockAccount({
      firstname: 'John',
      lastname: 'Doe',
    })
  })

  afterEach(() => {
    vi.spyOn(console, 'log').mockRestore()
  })

  it('shows the avatar', async () => {
    mockActiveAvatar()

    const view = await visitView('/account/avatar')

    await checkShownAvatar(view, `url(${mockAvatarImage})`)
  })

  it('can remove avatar', async () => {
    mockActiveAvatar()
    mockDeleteAvatar()

    const view = await visitView('/account/avatar')

    await view.findByText('Delete')
    await checkShownAvatar(view, `url(${mockAvatarImage})`)

    await removeAvatar(view)

    const avatar = await view.findByTestId('common-avatar')
    expect(avatar).toHaveTextContent('JD')
  })

  it('can not remove undeletable avatars', async () => {
    mockActiveAvatar(false)
    mockDeleteAvatar()

    const view = await visitView('/account/avatar')

    await view.findByTestId('common-avatar')
    const deleteButton = await view.findByText('Delete')

    expect(deleteButton).toHaveAttribute('disabled')
  })

  it('can upload image from camera', async () => {
    mockAddAvatar()
    mockActiveAvatar()

    const view = await visitView('/account/avatar')

    await uploadFile(view, 'fileCameraInput')
    await checkShownAvatar(view, `url(${mockAvatarImage})`)
  })

  it('can upload image from gallery', async () => {
    mockAddAvatar()
    mockActiveAvatar()

    const view = await visitView('/account/avatar')

    await uploadFile(view, 'fileGalleryInput')
    await checkShownAvatar(view, `url(${mockAvatarImage})`)
  })

  it('even after deleting I can upload an image', async () => {
    mockAddAvatar()
    mockActiveAvatar()
    mockDeleteAvatar()

    const view = await visitView('/account/avatar')

    await view.findByTestId('common-avatar')
    await checkShownAvatar(view, `url(${mockAvatarImage})`)

    await removeAvatar(view)

    await uploadFile(view, 'fileGalleryInput')
    await checkShownAvatar(view, `url(${mockAvatarImage})`)
  })

  it('after selecting image I can cancel the cropping', async () => {
    mockActiveAvatar()

    const view = await visitView('/account/avatar')

    const file = new File([], 'test.jpg', { type: 'image/jpeg' })
    await view.events.upload(view.getByTestId('fileGalleryInput'), file)

    const cancelButton = await view.findByText('Cancel')
    expect(cancelButton).toBeInTheDocument()
    await view.events.click(view.getByText('Cancel'))

    await checkShownAvatar(view, `url(${mockAvatarImage})`)
  })
})
