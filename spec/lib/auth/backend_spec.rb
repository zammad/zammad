# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Auth::Backend do

  let(:user)     { create(:user) }
  let(:password) { 'secure' }
  let(:auth)     { Auth.new(user.login, password) }
  let(:instance) { described_class.new(auth) }

  describe '#valid?' do

    context 'when invalid Setting is present in DB' do

      context 'when value is blank' do

        before do
          create(:setting,
                 area:  'Security::Authentication',
                 state: {},)
        end

        it "doesn't raise an exception" do
          expect { instance.valid? }.not_to raise_exception
        end
      end

      context "when adapter can't be constantized" do
        before do
          create(:setting,
                 area:  'Security::Authentication',
                 state: {
                   adapter: 'This::Will::Never::Work'
                 },)
        end

        it "doesn't raise an exception" do
          expect { instance.valid? }.not_to raise_exception
        end
      end
    end

    context 'when backend prioritization is relevant' do

      let(:previous_class_namespace) { 'Auth::Backend::TopPrio' }
      let(:later_class_namespace) { 'Auth::Backend::LeastPrio' }

      let(:previous_backend_class) { Class.new(Auth::Backend::Base) }
      let(:later_backend_class) { Class.new(Auth::Backend::Base) }

      let(:previous_backend_instance) { instance_double(previous_class_namespace) }
      let(:later_backend_instance) { instance_double(later_class_namespace) }

      before do
        stub_const previous_class_namespace, previous_backend_class
        stub_const later_class_namespace, later_backend_class

        Setting.where(area: 'Security::Authentication').destroy_all

        create(:setting,
               area:  'Security::Authentication',
               state: {
                 adapter:  previous_class_namespace,
                 priority: 1
               },)
        create(:setting,
               area:  'Security::Authentication',
               state: {
                 adapter:  later_class_namespace,
                 priority: 2
               },)

        allow(previous_class_namespace.constantize).to receive(:new).and_return(previous_backend_instance)
        allow(later_class_namespace.constantize).to receive(:new).and_return(later_backend_instance)

        allow(previous_backend_instance).to receive(:valid?)
        allow(later_backend_instance).to receive(:valid?)
      end

      context 'when previous backend was valid' do

        before do
          allow(previous_backend_instance).to receive(:valid?).and_return(true)
        end

        it "doesn't call valid on later backend" do
          instance.valid?

          expect(later_backend_instance).not_to have_received(:valid?)
        end
      end

      context 'when previous backend was not valid' do

        before do
          allow(previous_backend_instance).to receive(:valid?).and_return(false)
        end

        it 'calls valid on later backend' do
          instance.valid?

          expect(later_backend_instance).to have_received(:valid?)
        end
      end
    end
  end
end
