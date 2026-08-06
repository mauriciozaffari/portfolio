require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "responds successfully without a database" do
      get root_path

      expect(response).to have_http_status(:ok)
    end
  end
end
