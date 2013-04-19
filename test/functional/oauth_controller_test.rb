require 'test_helper'

class OauthControllerTest < ActionController::TestCase
  test "should get login" do
    get :login
    assert_response :success
  end

end
