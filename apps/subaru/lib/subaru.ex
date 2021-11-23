defmodule Subaru do
  alias Subaru.DB

  def add_v(v) do
    DB.insert(v.doc, v.collection)
  end
end
