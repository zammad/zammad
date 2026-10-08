# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SignatureConvertImagesToCid, type: :db_migration do
  let(:body_with_inline_image) { 'Yours truly, <img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAADAAEDAREAAhEBAxEB/8QAFAABAAAAAAAAAAAAAAAAAAAACv/EABQQAQAAAAAAAAAAAAAAAAAAAAD/xAAUAQEAAAAAAAAAAAAAAAAAAAAF/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AbgQDv//Z">' }
  let(:signature_with_image)   { UserInfo.with_user_id(1) { create(:signature, body: 'Yours truly') } }

  before do
    # Bypass the rich text callback, which would convert the image on its own.
    signature_with_image.update_columns(body: body_with_inline_image)
  end

  it 'converts image URLs to CID format' do
    expect { migrate }
      .to change { signature_with_image.reload.body }
      .from(body_with_inline_image)
      .to(match(%r{Yours truly, <img src="cid:Signature_body.(\S+)">}))
  end
end
