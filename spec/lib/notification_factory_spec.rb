# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe NotificationFactory do
  # WARNING: This spec relies on the presence of
  #          *actual* view templates in the app/ directory.
  #          Deleting them from the repo will break the tests!
  describe '::template_read' do
    let(:rendered_locale) { 'en' }
    let(:parsed_template) { { subject: template_lines.first, body: template_lines.drop(1).join } }
    let(:template_lines) { File.readlines(template_path) }
    let(:template_path) { Rails.root.join("app/views/mailer/signup/#{rendered_locale}.html.erb") }

    let(:read_params) do
      { type: 'mailer', template: 'signup', locale: 'en', format: 'html' }
    end

    it 'returns template file content as { subject: <first line>, body: <rest of file> }' do
      expect(described_class.template_read(read_params))
        .to eq(parsed_template)
    end

    context 'when selecting a template file to render' do
      # see https://github.com/zammad/zammad/issues/845#issuecomment-395084348
      context 'and file with ‘.custom’ suffix is available' do
        let(:template_path) { Rails.root.to_s + "/app/views/mailer/signup/#{rendered_locale}.html.erb.custom" }

        it 'uses that file' do

          File.write(template_path, "Subject\nBody\nbody\n")

          expect(described_class.template_read(read_params))
            .to eq({ subject: "Subject\n", body: "Body\nbody\n" })
        ensure
          File.delete(template_path)

        end
      end

      context 'if no locale given in arguments, and no default locale is set' do
        before { Setting.set('locale_default', nil) }

        it 'renders en-us template' do
          expect(described_class.template_read(read_params.except(:locale)))
            .to eq(parsed_template)
        end
      end

      context 'if no locale given in arguments, but default locale is set' do
        before { Setting.set('locale_default', 'de-de') }

        let(:rendered_locale) { 'de' }

        it 'tries template for default locale' do
          expect(described_class.template_read(read_params.except(:locale)))
            .to eq(parsed_template)
        end

        context 'and no such template exists' do
          before { Setting.set('locale_default', 'xx') }

          let(:rendered_locale) { 'en' }

          it 'falls back to en template' do
            expect(described_class.template_read(read_params.except(:locale)))
              .to eq(parsed_template)
          end
        end
      end

      context 'if locale given in arguments' do
        let(:rendered_locale) { 'de' }

        it 'tries template for given locale' do
          expect(described_class.template_read(read_params.merge(locale: 'de-de')))
            .to eq(parsed_template)
        end

        context 'and no such template exists' do
          let(:rendered_locale) { 'en' }

          it 'falls back to en template' do
            expect(described_class.template_read(read_params.merge(locale: 'xx')))
              .to eq(parsed_template)
          end
        end
      end
    end
  end

  describe '::application_template_read' do
    let(:read_params) { { type: 'mailer', format: 'html' } }
    let(:template_path) { Rails.root.join('app/views/mailer/application.html.erb') }

    it 'returns template file content as string' do
      expect(described_class.application_template_read(read_params))
        .to eq(File.read(template_path))
    end
  end
end
