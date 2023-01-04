// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

describe('log', () => {
  afterAll(() => {
    vi.restoreAllMocks()
  })

  beforeEach(() => {
    vi.spyOn(console, 'error').mockReturnValue()
    vi.spyOn(console, 'warn').mockReturnValue()
    vi.spyOn(console, 'info').mockReturnValue()
    vi.spyOn(console, 'log').mockReturnValue()
    vi.spyOn(console, 'trace').mockReturnValue()
  })

  it('logs with default log level', async (context) => {
    const { default: log } = await import('../log')

    context.skipConsole = true

    log.error('error')
    log.warn('warn')
    log.info('info')
    log.debug('debug')
    log.trace('trace')
    expect(console.error).toHaveBeenCalledTimes(1)
    expect(console.warn).toHaveBeenCalledTimes(1)
    // This verifies our custom default log level INFO
    expect(console.info).toHaveBeenCalledTimes(1)
    expect(console.log).toHaveBeenCalledTimes(0)
    expect(console.trace).toHaveBeenCalledTimes(0)
    log.setLevel('trace')
    log.error('error')
    log.warn('warn')
    log.info('info')
    log.debug('debug')
    log.trace('trace')
    // It seems trace also calls error().
    expect(console.error).toHaveBeenCalledTimes(2)
    expect(console.warn).toHaveBeenCalledTimes(2)
    expect(console.info).toHaveBeenCalledTimes(2)
    expect(console.log).toHaveBeenCalledTimes(1)
    expect(console.trace).toHaveBeenCalledTimes(1)
  })
})
