# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require_dependency 'zammad/application/initializer/session_store'

RSpec.describe Zammad::Application::Initializer::SessionStore do
  describe '.perform' do
    context 'for HTTP deployment' do
      before { Setting.set('http_type', 'http') }

      # Why not use the "change" matcher in this example?
      #
      # This initializer is already run when the application is loaded for testing.
      # Since the test env always uses http, the :secure option is already set to false.
      it 'adds { secure: false } to application session options' do
        described_class.perform

        expect(Rails.application.config.session_options).to include(secure: false)
      end
    end

    context 'for HTTPS deployment' do
      before { Setting.set('http_type', 'https') }

      it 'adds { secure: true } to application session options' do
        expect { described_class.perform }
          .to change(Rails.application.config, :session_options)
          .to include(secure: true)
      end
    end
  end
end
