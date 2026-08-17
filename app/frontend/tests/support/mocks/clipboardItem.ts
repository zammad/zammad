// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export class ClipboardItemMock {
  constructor(
    public data: Record<string, Blob | string | Promise<Blob | string>>,
    public options: { presentationStyle: 'unspecified' | 'inline' | 'attachment' } = {
      presentationStyle: 'unspecified',
    },
  ) {}
}

// Tests only store string flavours, so narrow the type for convenient assertions.
export const getClipboardItemData = (item: ClipboardItem) =>
  (item as unknown as ClipboardItemMock).data as Record<string, string>
