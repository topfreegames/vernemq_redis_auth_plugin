defmodule RedisAuthPluginTest do
  use ExUnit.Case

  @user "such_user"
  @admin_user "admin_much_user"
  @pass "much_password"
  @wtopic "much/chat/write"
  @wtopic_param [<<"much">>, <<"chat">>, <<"write">>]
  @wtopic_wildcard "much/wildcard/+"
  @wtopic_wildcard_string "much/wildcard/chat"
  @wtopic_wildcard_param [<<"much">>, <<"wildcard">>, <<"chat">>]
  @wtopic_param [<<"much">>, <<"chat">>, <<"write">>]
  @rtopic "much/chat/read"
  @rtopic_param [<<"much">>, <<"chat">>, <<"read">>]
  @encrypted_pass "PBKDF2$sha256$1000$jpZlWoGyBrmwDn5L$tBZHHs52NErO9tz5exw1QiJ03f5b/bfq"
  @invalid_credentials {:error, :invalid_credentials}
  @ok :ok

  setup_all do
    RedisAuthPlugin.command(["SET", @admin_user, @encrypted_pass])
    RedisAuthPlugin.command(["SET", @user, @encrypted_pass])
    RedisAuthPlugin.command(["SET", @user <> "-" <> @wtopic, 2])
    RedisAuthPlugin.command(["SET", @user <> "-" <> @wtopic_wildcard, 2])
    RedisAuthPlugin.command(["SET", @user <> "-" <> @rtopic, 1])
    :ok
  end

  test "right password" do
    assert RedisAuthPlugin.test_password(@encrypted_pass, @pass) == true
  end

  test "when user doesn't exist" do
    assert RedisAuthPlugin.validate_user("not_user", "some_pass") == @invalid_credentials
  end

  test "when user exist" do
    assert RedisAuthPlugin.validate_user(@user, @pass) == @ok
    assert RedisAuthPlugin.auth_on_register(nil, nil, @user, @pass, nil) == @ok
  end

  test "when user can publish topic" do
    assert RedisAuthPlugin.can_publish_topic(@user, @wtopic) == @ok
    assert RedisAuthPlugin.auth_on_publish(@user, nil, nil, @wtopic_param, nil, nil) == @ok

    assert RedisAuthPlugin.can_publish_topic(@admin_user, @wtopic) == @ok
    assert RedisAuthPlugin.auth_on_publish(@admin_user, nil, nil, @wtopic_param, nil, nil) == @ok
  end

  test "when admin user can publish or subscribe to wildcard topic" do
    assert RedisAuthPlugin.can_subscribe_topic(@user, "#") == :error
    assert RedisAuthPlugin.can_publish_topic(@user, "#") == :error
    assert RedisAuthPlugin.auth_on_subscribe(@user, nil, [{[<<"#">>], nil}]) == :error
    assert RedisAuthPlugin.auth_on_publish(@user, nil, nil, [<<"#">>], nil, nil) == :error
  end

  test "when user can publish to wildcard topic" do
    assert RedisAuthPlugin.can_publish_topic(@user, @wtopic_wildcard_string) == @ok
    assert RedisAuthPlugin.auth_on_publish(@user, nil, nil, @wtopic_wildcard_param, nil, nil) == @ok

    assert RedisAuthPlugin.can_publish_topic(@admin_user, @wtopic_wildcard_string) == @ok
    assert RedisAuthPlugin.auth_on_publish(@admin_user, nil, nil, @wtopic_wildcard_param, nil, nil) == @ok
  end

  test "when user can subscribe topic" do
    assert RedisAuthPlugin.can_subscribe_topic(@user, @wtopic) == @ok
    assert RedisAuthPlugin.can_subscribe_topic(@user, @rtopic) == @ok
    assert RedisAuthPlugin.auth_on_subscribe(@user, nil, [{@wtopic_param, nil}]) == @ok
    assert RedisAuthPlugin.auth_on_subscribe(@user, nil, [{@rtopic_param, nil}]) == @ok

    assert RedisAuthPlugin.can_subscribe_topic(@admin_user, @wtopic) == @ok
    assert RedisAuthPlugin.can_subscribe_topic(@admin_user, @rtopic) == @ok
    assert RedisAuthPlugin.auth_on_subscribe(@admin_user, nil, [{@wtopic_param, nil}]) == @ok
    assert RedisAuthPlugin.auth_on_subscribe(@admin_user, nil, [{@rtopic_param, nil}]) == @ok
  end

  test "when user cannot subscribe or publish topic" do
    assert RedisAuthPlugin.can_subscribe_topic(@user, "such-topic") == :error
    assert RedisAuthPlugin.can_publish_topic(@user, "such-topic") == :error
    assert RedisAuthPlugin.auth_on_subscribe(@user, nil, [{[<<"such-topic">>], nil}]) == :error
    assert RedisAuthPlugin.auth_on_publish(@user, nil, nil, [<<"such-topic">>], nil, nil) == :error
  end
end
