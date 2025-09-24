require "test_helper"

class MobsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get mobs_index_url
    assert_response :success
  end

  test "should get show" do
    get mobs_show_url
    assert_response :success
  end

  test "should get debug_error" do
    get mobs_debug_error_url
    assert_response :success
  end
end
