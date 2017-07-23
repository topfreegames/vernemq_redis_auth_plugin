defmodule AuthPluginTest do
  use ExUnit.Case
  doctest AuthPlugin

  test "the truth" do
    pass = "much_password"
    dbResponse = "PBKDF2$sha256$901$jpZlWoGyBrmwDn5L$IY5sZpV8y8az/s/81OeQ2511Um8rKtko"
    assert AuthPlugin.test_password(dbResponse, pass) == true
  end
end
