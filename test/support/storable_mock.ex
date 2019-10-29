defmodule EffDB.TestSupport.StorableMock do
  def create(file) do
    file
  end

  def set_defaults(_storable, _cluster_db, _options \\ %{}) do
    %{set_defaults: %{}}
  end
end