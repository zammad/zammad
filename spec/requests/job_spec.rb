# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Job', performs_jobs: true, type: :request do
  describe 'POST /api/v1/jobs/:id/run' do
    let(:job)   { create(:job, active: false) }
    let(:admin) { create(:admin) }
    let(:agent) { create(:agent) }

    context 'with an admin' do
      before { authenticated_as(admin) }

      it 'enqueues a run' do
        expect { post "/api/v1/jobs/#{job.id}/run", as: :json }
          .to have_enqueued_job(JobRunJob).with(job.id)
      end

      it 'responds with accepted' do
        post "/api/v1/jobs/#{job.id}/run", as: :json

        expect(response).to have_http_status(:accepted)
      end

      it 'does not change the job schedule' do
        expect { post "/api/v1/jobs/#{job.id}/run", as: :json }
          .to not_change { job.reload.attributes.slice('active', 'timeplan', 'next_run_at') }
      end

      context 'when the job is already running' do
        before { job.update_columns(running: true, last_run_at: 1.minute.ago) }

        it 'does not enqueue a run' do
          expect { post "/api/v1/jobs/#{job.id}/run", as: :json }
            .not_to have_enqueued_job(JobRunJob)
        end

        it 'responds with unprocessable content' do
          post "/api/v1/jobs/#{job.id}/run", as: :json

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    context 'without the scheduler permission' do
      before { authenticated_as(agent) }

      it 'does not enqueue a run' do
        expect { post "/api/v1/jobs/#{job.id}/run", as: :json }
          .not_to have_enqueued_job(JobRunJob)
      end

      it 'responds with forbidden' do
        post "/api/v1/jobs/#{job.id}/run", as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
