defmodule AuthPluginTest do
  use ExUnit.Case
  doctest AuthPlugin

  @user "such_user"
  @pass "much_password"
  @wtopic "much/chat/write"
  @rtopic "much/chat/read"
  @encrypted_pass "PBKDF2$sha256$901$jpZlWoGyBrmwDn5L$IY5sZpV8y8az/s/81OeQ2511Um8rKtko"

  setup do
    {:ok, auth_plugin} = AuthPlugin.start_link
    AuthPlugin.command(["SET", @user, @encrypted_pass])
    AuthPlugin.command(["SET", @user <> "-" <> @wtopic, 2])
    AuthPlugin.command(["SET", @user <> "-" <> @rtopic, 1])
    {:ok, auth_plugin: auth_plugin}
  end

  test "right password" do
    assert AuthPlugin.test_password(@encrypted_pass, @pass) == true
  end

  test "when user doesn't exist" do
    assert AuthPlugin.validate_user("not_user", "some_pass") == false
  end

  test "when user exist" do
    assert AuthPlugin.validate_user(@user, @pass) == true
  end

  test "when user can publish topic" do
    assert AuthPlugin.can_publish_topic(@user, @wtopic) == true
  end

  test "when user can subscribe topic" do
    assert AuthPlugin.can_subscribe_topic(@user, @wtopic) == true
    assert AuthPlugin.can_subscribe_topic(@user, @rtopic) == true
  end

  test "when user cannot subscribe or publish topic" do
    assert AuthPlugin.can_subscribe_topic(@user, "such-topic") == false
    assert AuthPlugin.can_publish_topic(@user, "such-topic") == false
  end
end
