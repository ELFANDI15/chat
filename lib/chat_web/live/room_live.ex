defmodule ChatWeb.RoomLive do
  require Logger
  use ChatWeb, :live_view

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    topic = "room:" <> room_id
    username = MnemonicSlugs.generate_slug()
    if connected?(socket) do
      ChatWeb.Endpoint.subscribe(topic)
      ChatWeb.Presence.track(self(), topic, username, %{})
    end

    {:ok,
    assign(socket,
      room_id: room_id,
      username: username,
      topic: topic,
      message: "",
      messages: [],
      temporary_assigns: [messages: []]
      )}
  end

  @impl true
  def handle_event("submit_message", %{"chat" => %{"message" => message}}, socket) do
    message = %{uuid: UUID.uuid4(), content: message, username: socket.assigns.username}
    ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", message)
    {:noreply, assign(socket, message: "")}
  end

  @impl true
  def handle_event("form_update", %{"chat" => %{"message" => message}}, socket) do
    {:noreply, assign(socket, message: message)}
  end

  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    {:noreply, assign(socket, messages: [message])}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    join_messages =
        joins
        |> Map.keys()
        |> Enum.map(fn username ->
          %{type: :system, uuid: UUID.uuid4(), content: "#{username} joined"}
        end)

    left_messages =
        leaves
        |> Map.keys()
        |> Enum.map(fn username ->
          %{type: :system, uuid: UUID.uuid4(), content: "#{username} left"} end)

    {:noreply, assign(socket, messages: join_messages ++ left_messages)}
  end

  def display_message(%{type: :system, uuid: uuid, content: content}) do
    ~E"""
    <p id="<%= uuid %>" > <em> <%= content %> </em> </p>
    """
  end

  def display_message(%{uuid: uuid, content: content, username: username}) do
    ~E"""
    <p id="<%= uuid %>" > <strong> <%= username %>: </strong>  <%= content %> </p>
    """
  end

end
