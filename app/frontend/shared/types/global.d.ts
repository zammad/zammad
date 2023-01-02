// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

declare type LogLevel = 'trace' | 'debug' | 'info' | 'warn' | 'error' | 'silent'

declare type Maybe<T> = T | null

declare global {
  interface Window {
    __(source: string): string
    setLogLevel(level: LogLevel, persistent: boolean): void
  }
}

declare function __(source: string): string
declare function setLogLevel(level: LogLevel, persistent: boolean): void
