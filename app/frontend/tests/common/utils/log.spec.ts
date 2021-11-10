// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import mockConsole from 'jest-mock-console'

// Needs to be done before importing log
mockConsole(['error', 'warn', 'info', 'log', 'trace'])

// eslint-disable-next-line import/first
import log from '@common/utils/log'

describe('log', () => {
  it('logs with default log level', () => {
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
    expect(console.error).toHaveBeenCalledTimes(2)
    expect(console.warn).toHaveBeenCalledTimes(2)
    expect(console.info).toHaveBeenCalledTimes(2)
    expect(console.log).toHaveBeenCalledTimes(1)
    expect(console.trace).toHaveBeenCalledTimes(1)
  })
})
