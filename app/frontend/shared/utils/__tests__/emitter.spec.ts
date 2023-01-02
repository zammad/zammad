// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import emitter from '../emitter'

describe('emitter', () => {
  it('check working emitter object', () => {
    const emitCallbackSpy = vi.fn()

    emitter.on('sessionInvalid', emitCallbackSpy)

    emitter.emit('sessionInvalid')

    expect(emitCallbackSpy).toHaveBeenCalled()
  })
})
