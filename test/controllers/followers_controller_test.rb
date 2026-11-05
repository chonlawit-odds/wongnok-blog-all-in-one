require "test_helper"

class FollowersControllerTest < ActionDispatch::IntegrationTest
  test "index has the follow form" do
    get posts_url
    assert_select "form[action=?] input[type=email][name='follower[email]']", followers_path
  end

  test "should get new" do
    get new_follower_url
    assert_response :success
  end

  test "create follows the blog" do
    assert_difference("Follower.count") do
      post followers_url, params: { follower: { email: " New@Example.com " } }
    end

    assert_redirected_to posts_url
    assert_equal "new@example.com", Follower.order(:id).last.email
  end

  test "invalid email re-renders the form with 422" do
    assert_no_difference("Follower.count") do
      post followers_url, params: { follower: { email: "not-an-email" } }
    end

    assert_response :unprocessable_content
    assert_select "input.input-error[name='follower[email]']"
  end
end
