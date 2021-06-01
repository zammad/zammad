# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue2541FixNotificationEmailWithoutBody, type: :db_migration do
  describe '"body" attribute management' do
    # We use #update_columns to bypass callbacks
    # that would prevent the record from being saved with an empty body
    before { subject.update_columns(perform: perform) }

    let(:perform) do
      {
        type => {
          'body'      => '',
          'recipient' => 'article_last_sender',
          'subject'   => 'Thanks for your inquiry (#{ticket.title})', # rubocop:disable Lint/InterpolationCheck
        },
      }
    end

    context 'when migrating Triggers' do
      subject(:trigger) { create(:trigger) }

      context 'for email' do
        let(:type) { 'notification.email' }

        it "updates empty perform['notification.email']['body'] attribute" do
          expect { migrate }.to change { trigger.reload.perform['notification.email']['body'] }.from('').to('-')
        end
      end

      context 'for SMS' do
        let(:type) { 'notification.sms' }

        it "updates empty perform['notification.sms']['body'] attribute" do
          expect { migrate }.to change { trigger.reload.perform['notification.sms']['body'] }.from('').to('-')
        end
      end
    end

    context 'when migrating Jobs' do
      subject(:job) { create(:job) }

      let(:type) { 'notification.email' }

      it "updates empty perform['notification.email']['body'] attribute" do
        expect { migrate }.to change { job.reload.perform['notification.email']['body'] }.from('').to('-')
      end

      context 'when selector contains current_user.id' do
        subject(:job) do
          UserInfo.ensure_current_user_id do

            create(:job, condition: { 'ticket.owner_id' => { 'operator' => 'is', 'pre_condition' => 'current_user.id', 'value' => '', 'value_completion' => '' } } )
          end
        end

        let(:type) { 'notification.email' }

        it "updates empty perform['notification.email']['body'] attribute" do
          expect { migrate }.to change { job.reload.perform['notification.email']['body'] }.from('').to('-')
        end
      end
    end

  end

  describe 'scheduler management' do
    let(:scheduler) { Scheduler.find_by(method: 'Job.run') }

    before { scheduler.update!(active: false) }

    it "re-enables 'Job.run' Scheduler" do
      expect { migrate }.to change { scheduler.reload.active }.to(true)
    end
  end
end
