require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index at root" do
    get root_url
    assert_response :success
    assert_select "nav.navbar"
    assert_select "h1", /Selamat datang/
  end
end
