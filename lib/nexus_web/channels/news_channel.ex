defmodule NexusWeb.NewsChannel do
  use NexusWeb, :channel

  def join("news:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("HackerNews", _payload, socket) do
    stories = ExHN.Live.top_stories() |> ExHN.Live.get_items() |> Enum.take(10)
    {:reply, {:ok, %{stories: stories}}, socket}
  end

  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
