defmodule CommandTest do
  use ExUnit.Case

  alias Sue.Models.Message

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
end
