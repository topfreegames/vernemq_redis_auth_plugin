defmodule AuthPluginTest do
  use ExUnit.Case
  doctest AuthPlugin

  @user "such_user"
  @pass "much_password"
  @wtopic "much/chat/write"
  @rtopic "much/chat/read"
  @encrypted_pass "PBKDF2$sha256$901$jpZlWoGyBrmwDn5L$IY5sZpV8y8az/s/81OeQ2511Um8rKtko"
  @invalid_credentials {:error, :invalid_credentials}
  @ok :ok

  setup_all do
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
    assert AuthPlugin.validate_user("not_user", "some_pass") == @invalid_credentials
  end

  test "when user exist" do
    assert AuthPlugin.validate_user(@user, @pass) == @ok
    assert AuthPlugin.auth_on_register(nil, nil, @user, @pass, nil) == @ok
  end

  test "when user can publish topic" do
    assert AuthPlugin.can_publish_topic(@user, @wtopic) == @ok
    assert AuthPlugin.auth_on_publish(@user, nil, nil, @wtopic, nil, nil) == @ok
  end

  test "when user can subscribe topic" do
    assert AuthPlugin.can_subscribe_topic(@user, @wtopic) == @ok
    assert AuthPlugin.can_subscribe_topic(@user, @rtopic) == @ok
    assert AuthPlugin.auth_on_subscribe(@user, nil, [{@wtopic, nil}]) == @ok
    assert AuthPlugin.auth_on_subscribe(@user, nil, [{@rtopic, nil}]) == @ok
  end

  test "when user cannot subscribe or publish topic" do
    assert AuthPlugin.can_subscribe_topic(@user, "such-topic") == :error
    assert AuthPlugin.can_publish_topic(@user, "such-topic") == :error
    assert AuthPlugin.auth_on_subscribe(@user, nil, [{"such-topic", nil}]) == :error
    assert AuthPlugin.auth_on_publish(@user, nil, nil, "such-topic", nil, nil) == :error
  end
end
