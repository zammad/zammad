import * as log from 'loglevel'

// Use INFO as default log level rather than WARN.
log.setDefaultLevel(log.levels.INFO)

// Register window.setLogLevel to allow for manual changing for debugging.
;(window as any).setLogLevel = (level: log.LogLevelDesc): void => {
  return log.setLevel(level)
}

// Usage:

// // Logging in code:
// import log from '@common/util/log'
// log.error('error message', ...)
// log.warn('warn message', ...)
// log.info('info message', ...)
// log.debug('debug message', ...)
// log.trace('trace message', ...)

// // Manual changing of log level via JS console for debugging purposes:
// setLogLevel(log.levels.TRACE, false) // temporary
// setLogLevel(log.levels.TRACE)        // persistent via local storage

export default log
