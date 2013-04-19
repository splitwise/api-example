require 'test_helper'

class OctopiControllerTest < ActionController::TestCase
  setup do
    @octopus = octopi(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:octopi)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create octopus" do
    assert_difference('Octopus.count') do
      post :create, octopus: {  }
    end

    assert_redirected_to octopus_path(assigns(:octopus))
  end

  test "should show octopus" do
    get :show, id: @octopus
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @octopus
    assert_response :success
  end

  test "should update octopus" do
    put :update, id: @octopus, octopus: {  }
    assert_redirected_to octopus_path(assigns(:octopus))
  end

  test "should destroy octopus" do
    assert_difference('Octopus.count', -1) do
      delete :destroy, id: @octopus
    end

    assert_redirected_to octopi_path
  end
end
