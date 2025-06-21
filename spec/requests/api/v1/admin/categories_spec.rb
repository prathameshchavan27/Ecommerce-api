require 'rails_helper'

RSpec.describe "Api::V1::Admin::Categories", type: :request do
  let(:admin) { create(:user, role: 'admin') }
  let(:headers) { auth_headers(admin) }
  let!(:category) { create(:category, name: 'Old Name') }

  describe 'PUT /api/v1/admin/categories/:id' do
    it 'updates the category name' do
      put "/api/v1/admin/categories/#{category.id}", 
          params: { category: { name: 'Updated Name' } }, 
          headers: headers,
          as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['name']).to eq('Updated Name')
    end
  end

  describe 'DELETE /api/v1/admin/categories/:id' do
    it 'deletes the category' do
      expect {
        delete "/api/v1/admin/categories/#{category.id}", headers: headers
      }.to change(Category, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end
  end
end
