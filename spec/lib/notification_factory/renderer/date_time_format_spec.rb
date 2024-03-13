# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'NotificationFactory::Renderer > Date/Time format' do # rubocop:disable RSpec/DescribeClass
  let(:ticket)  { create(:ticket) }
  let(:objects) { { ticket: ticket } }
  let(:locale)  { 'en-us' }

  let(:renderer) do
    build(:notification_factory_renderer,
          objects:  objects,
          template: template,
          locale:   locale)
  end

  context 'when using specific date/time formats' do
    let(:template) { 'Ticket created at: <b>#{dt(ticket.created_at, "%Y-%m-%d %H:%M:%S", "America/Los_Angeles")}</b>' } # rubocop:disable Lint/InterpolationCheck

    it 'renders date/time in default format' do
      expect(renderer.render).to eq("Ticket created at: <b>#{ticket.created_at.in_time_zone('America/Los_Angeles').strftime('%Y-%m-%d %H:%M:%S')}</b>")
    end

    context 'with timezone' do
      let(:template) { 'Ticket created at: <b>#{dt(ticket.created_at, "%Y-%m-%d %H:%M:%S (America/Los_Angeles)", "America/Los_Angeles")}</b>' } # rubocop:disable Lint/InterpolationCheck

      it 'renders date/time with timezone' do
        expect(renderer.render).to eq("Ticket created at: <b>#{ticket.created_at.in_time_zone('America/Los_Angeles').strftime('%Y-%m-%d %H:%M:%S')} (America/Los_Angeles)</b>")
      end
    end

    context 'with escaped characters in format string' do
      let(:template) { 'Ticket created at: <b>#{dt(ticket.created_at, "%Y-%m-%d %H:%M:%S \'test\'", "America/Los_Angeles")}</b>' } # rubocop:disable Lint/InterpolationCheck

      it 'renders date/time with escaped characters' do
        expect(renderer.render).to eq("Ticket created at: <b>#{ticket.created_at.in_time_zone('America/Los_Angeles').strftime('%Y-%m-%d %H:%M:%S')} 'test'</b>")
      end
    end

    context 'with using a combination in format string' do
      context 'when using %+' do
        let(:template) { 'Ticket created at: <b>#{dt(ticket.created_at, "%+", "America/Los_Angeles")}</b>' } # rubocop:disable Lint/InterpolationCheck

        it 'renders date/time with escaped characters' do
          expect(renderer.render).to eq("Ticket created at: <b>#{ticket.created_at.in_time_zone('America/Los_Angeles').strftime('%+')}</b>")
        end
      end

      context 'when using %c' do
        let(:template) { 'Ticket created at: <b>#{dt(ticket.created_at, "%c", "America/Los_Angeles")}</b>' } # rubocop:disable Lint/InterpolationCheck

        it 'renders date/time with escaped characters' do
          expect(renderer.render).to eq("Ticket created at: <b>#{ticket.created_at.in_time_zone('America/Los_Angeles').strftime('%c')}</b>")
        end
      end
    end
  end

  context 'when omitting timezone' do
    before { Setting.set('timezone_default', 'Europe/Berlin') }

    let(:template) { 'Ticket created at: <b>#{dt(ticket.created_at, "%Y-%m-%d %H:%M:%S", "")}</b>' } # rubocop:disable Lint/InterpolationCheck

    it 'renders date/time with stored timezone' do
      expect(renderer.render).to eq("Ticket created at: <b>#{ticket.created_at.in_time_zone('Europe/Berlin').strftime('%Y-%m-%d %H:%M:%S')}</b>")
    end
  end

  context 'when omitting format string' do
    let(:template) { 'Ticket created at: <b>#{dt(ticket.created_at, "", "America/Los_Angeles")}</b>' } # rubocop:disable Lint/InterpolationCheck

    it 'renders date/time with default format string' do
      expect(renderer.render).to eq("Ticket created at: <b>#{ticket.created_at.in_time_zone('America/Los_Angeles').strftime('%Y-%m-%d %H:%M:%S')}</b>")
    end
  end

  context 'when omitting both format string and timezone' do
    before { Setting.set('timezone_default', 'Europe/Berlin') }

    context 'when both parameters are empty strings' do
      let(:template) { 'Ticket created at: <b>#{dt(ticket.created_at, "", "")}</b>' } # rubocop:disable Lint/InterpolationCheck

      it 'renders date/time with default format string and stored timezone' do
        expect(renderer.render).to eq("Ticket created at: <b>#{ticket.created_at.in_time_zone('Europe/Berlin').strftime('%Y-%m-%d %H:%M:%S')}</b>")
      end
    end

    context 'when both parameters are not present' do
      let(:template) { 'Ticket created at: <b>#{dt(ticket.created_at)}</b>' } # rubocop:disable Lint/InterpolationCheck

      it 'renders date/time with default format string' do
        expect(renderer.render).to eq("Ticket created at: <b>#{ticket.created_at.in_time_zone('Europe/Berlin').strftime('%Y-%m-%d %H:%M:%S')}</b>")
      end
    end
  end

  context 'when objects are missing' do
    let(:objects)  { {} }
    let(:template) { 'Ticket created at: <b>#{dt(ticket.created_at, "%Y-%m-%d %H:%M:%S", "America/Los_Angeles")}</b>' } # rubocop:disable Lint/InterpolationCheck

    context 'when debug mode is disabled' do
      it 'renders debug message' do
        expect(renderer.render(debug_errors: false)).to eq('Ticket created at: <b>-</b>')
      end
    end

    context 'when debug mode is enabled' do
      it 'renders debug message' do
        expect(renderer.render(debug_errors: true)).to eq("Ticket created at: <b>\#{ticket.created_at / invalid parameter}</b>")
      end
    end
  end

  context 'when providing potentially dangerous input' do
    let(:template) { 'Ticket created at: <b>#{dt(ticket.created_at, ticket.destroy!, "America/Los_Angeles")}</b>' } # rubocop:disable Lint/InterpolationCheck

    it 'parameters string_format, timezone always handled as string' do
      expect(renderer.render(debug_errors: true)).to eq('Ticket created at: <b>ticket.destroy!</b>')
    end
  end
end
