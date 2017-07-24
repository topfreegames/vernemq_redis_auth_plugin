defmodule AuthPlugin do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    pool_size = 5
    redix_workers = for i <- 0..(pool_size - 1) do
      worker(Redix, [[], [name: :"redix_#{i}"]], id: {Redix, i})
    end

    supervise(redix_workers, strategy: :one_for_one)
  end

  def validate_user(user, password) do
    db_string = get_user(user)
    if db_string != nil do
      test_password(db_string, password)
    else
      false
    end
  end

  def can_publish_topic(user, topic) do
    topic = get_topic(user, topic)
    topic > 1
  end

  def can_subscribe_topic(user, topic) do
    topic = get_topic(user, topic)
    topic > 0
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
