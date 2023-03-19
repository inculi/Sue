defmodule CommandTest do
  use ExUnit.Case

  alias Sue.Models.Message
  alias Sue.New.Schema

  test "ping" do
    m = Message.from_debug("!ping")
    response = Sue.debug_blocking_process_message(m)
    assert response.body == "pong!"
  end

  test "random" do
    m = Message.from_debug("!flip")
    response = Sue.debug_blocking_process_message(m)
    assert response.body in ["heads", "tails"]
  end

  test "defn" do
    Schema.debug_clear_collections()

    m = Message.from_debug("!megumin")
    response1 = Sue.debug_blocking_process_message(m)
    assert String.contains?(response1.body, "not found")

    m2 = Message.from_debug("!define megumin acute")
    response2 = Sue.debug_blocking_process_message(m2)
    assert String.contains?(response2.body, "updated")

    m3 = Message.from_debug("!megumin")
    response3 = Sue.debug_blocking_process_message(m3)
    assert response3.body == "acute"
  end
end
