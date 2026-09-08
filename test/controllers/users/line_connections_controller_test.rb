require "test_helper"

class Users::LineConnectionsControllerTest < ActionDispatch::IntegrationTest
  test "LINE連携を解除するとline_user_idとline_access_tokenがクリアされる" do
    user = users(:one)
    user.update!(line_user_id: "line-uid-1", line_access_token: "token-1")
    sign_in user

    delete disconnect_line_path

    assert_redirected_to edit_user_registration_path
    assert_equal "LINE連携を解除しました", flash[:notice]
    user.reload
    assert_nil user.line_user_id
    assert_nil user.line_access_token
  end

  test "未ログインならログイン画面にリダイレクトされる" do
    delete disconnect_line_path

    assert_redirected_to new_user_session_path
  end
end
