// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import emitter from '@common/utils/emitter'

describe('emitter', () => {
  it('check working emitter object', () => {
    const emitCallbackSpy = jest.fn()

    emitter.on('sessionInvalid', emitCallbackSpy)

    emitter.emit('sessionInvalid')

    expect(emitCallbackSpy).toHaveBeenCalled()
  })
})
