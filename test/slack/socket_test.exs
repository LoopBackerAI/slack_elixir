defmodule Slack.SocketTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Slack.TestBot

  @foo_event """
  {
    "envelope_id": "eid-234",
    "type": "foo",
    "payload": {
      "event": {
        "type": "foo",
        "channel": "channel-foo"
      }
    }
  }
  """

  @slash_command """
  {
    "envelope_id": "eid-567",
    "type": "slash_commands",
    "payload": {
      "channel_name": "directmessage",
      "command": "/mycmd",
      "text": "run this"
    }
  }
  """

  @message_action """
  {
    "envelope_id": "eid-789",
    "payload": {
        "type": "message_action",
        "team": {
            "id": "",
            "domain": ""
        },
        "user": {
            "id": "",
            "username": "",
            "team_id": "",
            "name": ""
        },
        "channel": {
            "id": "",
            "name": ""
        },
        "callback_id": "message_action_callback_id",
        "message": {
            "user": "user_id",
            "type": "message",
            "text": "Hello world!",
            "team": "team_id",
            "blocks": [
                {
                    "type": "rich_text",
                    "block_id": "block_id",
                    "elements": [
                        {
                            "type": "rich_text_section",
                            "elements": [
                                {
                                    "type": "text",
                                    "text": "Hello world!"
                                }
                            ]
                        }
                    ]
                }
            ]
        }
    },
    "type": "interactive",
    "accepts_response_payload": false
  }
  """

  @bot %Slack.Bot{
    id: "bot-123-ABC",
    module: TestBot,
    token: "bot-123-ABC",
    team_id: "team-123-ABC",
    user_id: "user-123-ABC"
  }

  setup :set_mimic_global

  setup do
    stub(Slack.API)
    start_supervised!({Registry, keys: :unique, name: Slack.MessageServerRegistry})

    start_supervised!(
      {PartitionSupervisor, child_spec: Task.Supervisor, name: Slack.TaskSupervisors}
    )

    :ok
  end

  test "bot can noop" do
    stub(Slack.API)

    state = %{bot: @bot}

    assert {:reply, ack_frame, _state} = Slack.Socket.handle_frame({:text, @foo_event}, state)
    assert {:text, ~S({"envelope_id":"eid-234"})} = ack_frame
  end

  test "socket can noop" do
    stub(Slack.API)

    assert {:ok, %{}} == Slack.Socket.handle_frame({:text, ""}, %{})
  end

  test "socket can handle a slash command" do
    stub(Slack.API)

    assert {:reply, {:text, ~S({"envelope_id":"eid-567"})}, %{}} =
             Slack.Socket.handle_frame({:text, @slash_command}, %{})
  end

  test "socket can handle a message action" do
    stub(Slack.API)

    assert {:reply, {:text, ~S({"envelope_id":"eid-789"})}, %{}} =
             Slack.Socket.handle_frame({:text, @message_action}, %{})
  end
end
