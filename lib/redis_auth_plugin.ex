defmodule RedisAuthPlugin.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    host = System.get_env("REDIS_AUTH_REDIS_HOST") || "localhost"
    port = String.to_integer(System.get_env("REDIS_AUTH_REDIS_PORT") || "6379")
    password = System.get_env("REDIS_AUTH_REDIS_PASSWORD") || nil
    pool_size = String.to_integer(System.get_env("REDIS_AUTH_REDIS_POOL_SIZE") || "5")
    redix_workers = for i <- 0..(pool_size - 1) do
      worker(Redix, [
        [host: host, port: port, password: password],
        [name: :"redix_#{i}"]
      ], id: {Redix, i})
    end

    supervise(redix_workers, strategy: :one_for_one)
  end
end

defmodule RedisAuthPlugin do
  def start(_type, _args) do
    IO.puts "*** plugin started"
    RedisAuthPlugin.Supervisor.start_link()
  end

  def auth_on_register(_, _, username, password, _) do
    validate_user(username, password)
  end

  def auth_on_publish(username, _, _, topic, _, _) do
    can_publish_topic(username, Enum.join(topic, "/"))
  end

  def auth_on_subscribe(username, _, [{topic, _}|_] = _topics) do
    can_subscribe_topic(username, Enum.join(topic, "/"))
  end

  def validate_user(user, password) do
    db_string = get_user(user)
    if db_string != nil and test_password(db_string, password) do
      :ok
    else
      {:error, :invalid_credentials}
    end
  end

  def can_publish_topic(user, topic) do
    topic = get_topic(user, topic)
    if topic > 1 do
      :ok
    else
      :error
    end
  end

  def can_subscribe_topic(user, topic) do
    topic = get_topic(user, topic)
    if topic > 0 do
      :ok
    else
      :error
    end
  end


  def command(command) do
    {:ok, result} = Redix.command(:"redix_#{random_index()}", command)
    result
  end

  def test_password(db_string, password) do
    [_, hash_string, iterations_string, salt, db_pass] = String.split(db_string, "$")
    hash = String.to_atom(hash_string)
    iterations = String.to_integer(iterations_string)
    key_length = String.length(db_pass)
    {:ok, res} = :pbkdf2.pbkdf2(
      hash,
      password,
      salt,
      iterations,
      key_length
    )
    result = String.slice(Base.encode64(res), 0, key_length)
    result == db_pass
  end

  defp get_topic(user, topic) do
    response = command(["get", user <> "-" <> topic])
    if response != nil do
      String.to_integer(response)
    else
      0
    end
  end

  defp get_user(user) do
    response = command(["GET", user])
    if response != nil do
      response
    end
  end

  defp random_index do
    rem(System.unique_integer([:positive]), 5)
  end
end
