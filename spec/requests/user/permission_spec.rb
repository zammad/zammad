# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'User endpoint', type: :request do

  let(:role_with_admin_user_permissions) do
    create(:role).tap do |role|
      role.permission_grant('admin.user')
    end
  end
  let(:admin_with_admin_user_permissions) { create(:user, roles: [role_with_admin_user_permissions]) }

  let(:role_without_admin_user_permissions) do
    create(:role).tap do |role|
      role.permission_grant('admin.tag')
    end
  end
  let(:admin_without_admin_user_permissions) { create(:user, roles: [role_without_admin_user_permissions]) }

  describe 'User creation' do

    let(:attributes) { attributes_params_for(:user) }

    it 'responds forbidden for customer' do
      requester = create(:customer)
      authenticated_as(requester)

      expect do
        post api_v1_users_path, params: attributes
      end.to not_change {
        User.count
      }

      expect(response).to have_http_status(:forbidden)
    end

    context 'privileged attributes' do

      context 'group assignment' do

        # group access assignment is in general only valid for agents
        # see HasGroups.groups_access_permission?
        let(:agent_attributes) do
          attributes.merge(
            roles: Role.where(name: 'Agent').map(&:name),
          )
        end

        shared_examples 'group assignment' do |map_method_id|

          it 'responds success for admin.user' do
            authenticated_as(admin_with_admin_user_permissions)

            expect do
              post api_v1_users_path, params: payload
            end.to change(User, :count).by(1)

            expect(response).to have_http_status(:success)
            expect(User.last.send(map_method_id)).to eq(send(map_method_id))
          end

          it 'responds forbidden for sub admin without admin.user' do
            authenticated_as(admin_without_admin_user_permissions)

            expect do
              post api_v1_users_path, params: payload
            end.to not_change {
              User.count
            }

            expect(response).to have_http_status(:forbidden)
          end

          it 'responds successful for agent but removes assignment' do
            requester = create(:agent)
            authenticated_as(requester)

            expect do
              post api_v1_users_path, params: payload
            end.to change(User, :count).by(1)

            expect(response).to have_http_status(:success)
            expect(User.last.send(map_method_id)).to be_blank
          end
        end

        context 'parameter groups' do

          let(:group_names_access_map) do
            Group.all.map { |g| [g.name, ['full']] }.to_h
          end

          let(:payload) do
            agent_attributes.merge(
              groups: group_names_access_map,
            )
          end

          it_behaves_like 'group assignment', :group_names_access_map
        end

        context 'parameter group_ids' do

          let(:group_ids_access_map) do
            Group.all.map { |g| [g.id, ['full']] }.to_h
          end

          let(:payload) do
            agent_attributes.merge(
              group_ids: group_ids_access_map,
            )
          end

          it_behaves_like 'group assignment', :group_ids_access_map
        end
      end

      context 'role assignment' do

        shared_examples 'role assignment' do

          let(:privileged) { Role.where(name: 'Admin') }

          it 'responds success for admin.user' do
            authenticated_as(admin_with_admin_user_permissions)

            expect do
              post api_v1_users_path, params: payload
            end.to change(User, :count).by(1)

            expect(response).to have_http_status(:success)
            expect(User.last.roles).to eq(privileged)
          end

          it 'responds forbidden for sub admin without admin.user' do
            authenticated_as(admin_without_admin_user_permissions)

            expect do
              post api_v1_users_path, params: payload
            end.to not_change {
              User.count
            }

            expect(response).to have_http_status(:forbidden)
          end

          it 'responds successful for agent but removes assignment' do
            requester = create(:agent)
            authenticated_as(requester)

            expect do
              post api_v1_users_path, params: payload
            end.to change(User, :count).by(1)

            expect(response).to have_http_status(:success)
            expect(User.last.roles).to eq(Role.signup_roles)
          end
        end

        context 'parameter roles' do
          let(:payload) do
            attributes.merge(
              roles: privileged.map(&:name),
            )
          end

          it_behaves_like 'role assignment'
        end

        context 'parameter role_ids' do
          let(:payload) do
            attributes.merge(
              role_ids: privileged.map(&:id),
            )
          end

          it_behaves_like 'role assignment'
        end
      end
    end
  end

  describe 'User update' do

    def authorized_update_request(requester:, requested:)
      authenticated_as(requester)

      expect do
        put api_v1_update_user_path(requested), params: cleaned_params_for(requested).merge(firstname: 'Changed')
      end.to change {
        requested.reload.firstname
      }

      expect(response).to have_http_status(:success)
    end

    def forbidden_update_request(requester:, requested:)
      authenticated_as(requester)

      expect do
        put api_v1_update_user_path(requested), params: cleaned_params_for(requested).merge(firstname: 'Changed')
      end.to not_change {
        requested.reload.attributes.tap do |attributes|
          # take attributes as they are for different users
          next if requester != requested

          # last_login and updated_at change every time
          # even if the record itself should not change
          attributes.delete_if do |key, _value|
            %w[last_login updated_at].include?(key)
          end
        end
      }

      expect(response).to have_http_status(:forbidden)
    end

    context 'request by admin.user' do

      let(:requester) { admin_with_admin_user_permissions }

      it 'is successful for same admin' do
        authorized_update_request(
          requester: requester,
          requested: requester,
        )
      end

      it 'is successful for other admin' do
        authorized_update_request(
          requester: requester,
          requested: create(:admin),
        )
      end

      it 'is successful for agent' do
        authorized_update_request(
          requester: requester,
          requested: create(:agent),
        )
      end

      it 'is successful for customer' do
        authorized_update_request(
          requester: requester,
          requested: create(:customer),
        )
      end
    end

    context 'request by sub admin without admin.user' do

      let(:requester) { admin_without_admin_user_permissions }

      it 'is forbidden for same admin' do
        forbidden_update_request(
          requester: requester,
          requested: requester,
        )
      end

      it 'is forbidden for other admin' do
        forbidden_update_request(
          requester: requester,
          requested: create(:admin),
        )
      end

      it 'is forbidden for agent' do
        forbidden_update_request(
          requester: requester,
          requested: create(:agent),
        )
      end

      it 'is forbidden for customer' do
        forbidden_update_request(
          requester: requester,
          requested: create(:customer),
        )
      end
    end

    context 'request by agent' do

      let(:requester) { create(:agent) }

      it 'is forbidden for admin' do
        forbidden_update_request(
          requester: requester,
          requested: create(:admin),
        )
      end

      it 'is forbidden same agent' do
        forbidden_update_request(
          requester: requester,
          requested: requester,
        )
      end

      it 'is forbidden for other agent' do
        forbidden_update_request(
          requester: requester,
          requested: create(:agent),
        )
      end

      it 'is successful for customer' do
        authorized_update_request(
          requester: requester,
          requested: create(:customer),
        )
      end
    end

    context 'request by customer' do

      let(:requester) { create(:customer) }

      it 'is forbidden for admin' do
        forbidden_update_request(
          requester: requester,
          requested: create(:admin),
        )
      end

      it 'is forbidden for agent' do
        forbidden_update_request(
          requester: requester,
          requested: create(:agent),
        )
      end

      it 'is forbidden for same customer' do
        forbidden_update_request(
          requester: requester,
          requested: requester,
        )
      end

      it 'is forbidden for other customer' do
        forbidden_update_request(
          requester: requester,
          requested: create(:customer),
        )
      end

      it 'is forbidden for same organization' do
        same_organization = create(:organization)

        requester.update!(organization: same_organization)

        forbidden_update_request(
          requester: requester,
          requested: create(:customer, organization: same_organization),
        )
      end
    end

    context 'privileged attributes' do

      let(:requested) { create(:user) }
      let(:attribute) { privileged.keys.first }
      let(:payload) { cleaned_params_for(requested).merge(privileged) }

      def value_of_attribute
        # we need to call .to_a otherwise Rails will load the
        # ActiveRecord::Associations::CollectionProxy
        # on comparsion which is to late
        requested.reload.public_send(attribute).to_a
      end

      shared_examples 'admin types requests' do

        it 'responds success for admin.user' do
          authenticated_as(admin_with_admin_user_permissions)

          expect do
            put api_v1_update_user_path(requested), params: payload
          end.to change {
            value_of_attribute
          }
          expect(response).to have_http_status(:success)
        end

        it 'responds forbidden for sub admin without admin.user' do
          authenticated_as(admin_without_admin_user_permissions)

          expect do
            put api_v1_update_user_path(requested), params: payload
          end.to not_change {
            value_of_attribute
          }

          expect(response).to have_http_status(:forbidden)
        end
      end

      shared_examples 'permitted agent update' do

        it 'responds successful for agent but removes assignment' do
          requester = create(:agent)
          authenticated_as(requester)

          expect do
            put api_v1_update_user_path(requested), params: payload
          end.to change {
            value_of_attribute
          }

          expect(response).to have_http_status(:success)
        end
      end

      shared_examples 'forbidden agent update' do

        it 'responds successful for agent but removes assignment' do
          requester = create(:agent)
          authenticated_as(requester)

          expect do
            put api_v1_update_user_path(requested), params: payload
          end.to not_change {
            value_of_attribute
          }

          expect(response).to have_http_status(:success)
        end
      end

      context 'group assignment' do

        context 'parameter groups' do

          let(:privileged) do
            {
              groups: Group.all.map { |g| [g.name, ['full']] }.to_h
            }
          end

          it_behaves_like 'admin types requests'
          it_behaves_like 'forbidden agent update'
        end

        context 'parameter group_ids' do

          let(:privileged) do
            {
              group_ids: Group.all.map { |g| [g.id, ['full']] }.to_h
            }
          end

          it_behaves_like 'admin types requests'
          it_behaves_like 'forbidden agent update'
        end
      end

      context 'role assignment' do

        let(:admin_role) { Role.where(name: 'Admin') }

        context 'parameter roles' do
          let(:privileged) do
            {
              roles: admin_role.map(&:name),
            }
          end

          it_behaves_like 'admin types requests'
          it_behaves_like 'forbidden agent update'
        end

        context 'parameter role_ids' do
          let(:privileged) do
            {
              role_ids: admin_role.map(&:id),
            }
          end

          it_behaves_like 'admin types requests'
          it_behaves_like 'forbidden agent update'
        end
      end

      context 'organization assignment' do

        let(:new_organizations) { create_list(:organization, 2) }

        context 'parameter organizations' do
          let(:privileged) do
            {
              organizations: new_organizations.map(&:name),
            }
          end

          it_behaves_like 'admin types requests'
          it_behaves_like 'permitted agent update'
        end

        context 'parameter organization_ids' do
          let(:privileged) do
            {
              organization_ids: new_organizations.map(&:id),
            }
          end

          it_behaves_like 'admin types requests'
          it_behaves_like 'permitted agent update'
        end
      end
    end
  end

  describe 'User deletion' do

    def authorized_destroy_request(requester:, requested:)
      authenticated_as(requester)

      delete api_v1_delete_user_path(requested)

      expect(response).to have_http_status(:success)
      expect(requested).not_to exist_in_database
    end

    def forbidden_destroy_request(requester:, requested:)
      authenticated_as(requester)

      delete api_v1_delete_user_path(requested)

      expect(response).to have_http_status(:forbidden)
      expect(requested).to exist_in_database
    end

    context 'request by admin.user' do

      let(:requester) { admin_with_admin_user_permissions }

      it 'is successful for same admin' do
        authorized_destroy_request(
          requester: requester,
          requested: requester,
        )
      end

      it 'is successful for other admin' do
        authorized_destroy_request(
          requester: requester,
          requested: create(:admin),
        )
      end

      it 'is successful for agent' do
        authorized_destroy_request(
          requester: requester,
          requested: create(:agent),
        )
      end

      it 'is successful for customer' do
        authorized_destroy_request(
          requester: requester,
          requested: create(:customer),
        )
      end
    end

    context 'request by sub admin without admin.user' do

      let(:requester) { admin_without_admin_user_permissions }

      it 'is forbidden for same admin' do
        forbidden_destroy_request(
          requester: requester,
          requested: requester,
        )
      end

      it 'is forbidden for other admin' do
        forbidden_destroy_request(
          requester: requester,
          requested: create(:admin),
        )
      end

      it 'is forbidden for agent' do
        forbidden_destroy_request(
          requester: requester,
          requested: create(:agent),
        )
      end

      it 'is forbidden for customer' do
        forbidden_destroy_request(
          requester: requester,
          requested: create(:customer),
        )
      end
    end

    context 'request by agent' do

      let(:requester) { create(:agent) }

      it 'is forbidden for admin' do
        forbidden_destroy_request(
          requester: requester,
          requested: create(:admin),
        )
      end

      it 'is forbidden same agent' do
        forbidden_destroy_request(
          requester: requester,
          requested: requester,
        )
      end

      it 'is forbidden for other agent' do
        forbidden_destroy_request(
          requester: requester,
          requested: create(:agent),
        )
      end

      it 'is forbidden for customer' do
        forbidden_destroy_request(
          requester: requester,
          requested: create(:customer),
        )
      end
    end

    context 'request by customer' do

      let(:requester) { create(:customer) }

      it 'is forbidden for admin' do
        forbidden_destroy_request(
          requester: requester,
          requested: create(:admin),
        )
      end

      it 'is forbidden for agent' do
        forbidden_destroy_request(
          requester: requester,
          requested: create(:agent),
        )
      end

      it 'is forbidden for same customer' do
        forbidden_destroy_request(
          requester: requester,
          requested: requester,
        )
      end

      it 'is forbidden for other customer' do
        forbidden_destroy_request(
          requester: requester,
          requested: create(:customer),
        )
      end

      it 'is forbidden for same organization' do
        same_organization = create(:organization)

        requester.update!(organization: same_organization)

        forbidden_destroy_request(
          requester: requester,
          requested: create(:customer, organization: same_organization),
        )
      end
    end
  end
end
