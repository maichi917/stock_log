require "test_helper"

class Users::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:line] = nil
  end

  def mock_line_auth(uid:, name: "LINE太郎", token: "token-abc")
    OmniAuth.config.mock_auth[:line] = OmniAuth::AuthHash.new(
      provider: "line",
      uid: uid,
      info: { name: name },
      credentials: { token: token }
    )
  end

  test "未ログイン・未登録のLINEアカウントなら新規ユーザーを作成してログインする" do
    mock_line_auth(uid: "line-uid-new")

    assert_difference "User.count", 1 do
      get user_line_omniauth_callback_path
    end

    user = User.find_by(line_user_id: "line-uid-new")
    assert user.present?
    assert_equal "LINE太郎", user.name
    assert_redirected_to home_path
    assert_equal "LINEアカウントで新規登録しました", flash[:notice]
  end

  test "登録済みのLINEアカウントなら既存ユーザーとしてログインする" do
    user = users(:one)
    user.update!(line_user_id: "line-uid-existing")
    mock_line_auth(uid: "line-uid-existing")

    assert_no_difference "User.count" do
      get user_line_omniauth_callback_path
    end

    assert_redirected_to home_path
    assert_equal "LINEアカウントでログインしました", flash[:notice]
  end

  test "ログイン中ユーザーが未連携のLINEアカウントで連携する" do
    user = users(:one)
    sign_in user
    mock_line_auth(uid: "line-uid-to-link")

    get user_line_omniauth_callback_path

    assert_redirected_to edit_user_registration_path
    assert_equal "LINEアカウントと連携しました", flash[:notice]
    assert_equal "line-uid-to-link", user.reload.line_user_id
  end

  test "ログイン中ユーザーが他アカウントで連携済みのLINEアカウントを使おうとすると失敗する" do
    other_user = users(:two)
    other_user.update!(line_user_id: "line-uid-taken")
    user = users(:one)
    sign_in user
    mock_line_auth(uid: "line-uid-taken")

    get user_line_omniauth_callback_path

    assert_redirected_to edit_user_registration_path
    assert_match "すでに別のアカウントと連携しています", flash[:alert]
    assert_nil user.reload.line_user_id
  end
end
