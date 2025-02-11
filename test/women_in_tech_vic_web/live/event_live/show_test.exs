defmodule WomenInTechVicWeb.EventLive.ShowTest do
  use WomenInTechVicWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions, only: [assert_email_sent: 0]

  import WomenInTechVic.Support.AccountsTestSetup,
    only: [user: 1, user_2: 1, profile: 1, subscription: 1]

  import WomenInTechVic.Support.ContentTestSetup, only: [online_event: 1, in_person_event: 1]

  alias WomenInTechVic.Accounts
  alias WomenInTechVic.Content
  alias WomenInTechVic.Content.Event

  setup [:user, :user_2, :online_event, :in_person_event, :profile, :subscription]

  describe "Show page" do
    test "renders a page with event info", %{conn: conn, user: user, online_event: online_event} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/events/#{online_event}")

      assert html =~ "meet.google"
      assert html =~ "Add to Google Calendar"
      refute html =~ "Show details"
    end

    test "renders a page with event info for in person meetings", %{
      conn: conn,
      user: user,
      in_person_event: in_person_event
    } do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/events/#{in_person_event}")

      assert html =~ "Pub around the Corner"
      refute html =~ "Show details"
    end

    test "adds a user to the list of event attendees when RSVP button is clicked", %{
      conn: conn,
      user: user,
      online_event: online_event
    } do
      online_event_id = online_event.id

      assert {:ok, %Event{id: ^online_event_id, online: true, attendees: []}} =
               Content.find_event(id: online_event.id, preload: :attendees)

      {:ok, lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/events/#{online_event}")

      assert html =~ "RSVP"

      assert lv
             |> element("button[phx-click=\"rsvp\"]")
             |> render_click(%{
               "event_id" => to_string(online_event_id),
               "user_id" => to_string(user.id)
             })

      assert {:ok, %Event{id: ^online_event_id, online: true, attendees: [^user]}} =
               Content.find_event(id: online_event.id, preload: :attendees)
    end

    test "shows different buttons for users that are attending vs not attending", %{
      conn: conn,
      user: user,
      online_event: online_event
    } do
      online_event_id = online_event.id

      {:ok, lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/events/#{online_event}")

      assert html =~ "I will be there"
      refute html =~ "I changed my mind"

      lv
      |> element("button[phx-click=\"rsvp\"]")
      |> render_click(%{
        "event_id" => to_string(online_event_id),
        "user_id" => to_string(user.id)
      })

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/events/#{online_event}")

      refute html =~ "I will be there"
      assert html =~ "I changed my mind"
    end

    test "attending users with a profile will have their name link to profile", %{
      conn: conn,
      user: user,
      user_2: user_2,
      online_event: online_event,
      profile: profile
    } do
      assert [^profile] = Accounts.all_profiles(%{})

      online_event_id = online_event.id

      {:ok, lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/events/#{online_event}")

      assert html =~ "I will be there"
      refute html =~ "I changed my mind"

      lv
      |> element("button[phx-click=\"rsvp\"]")
      |> render_click(%{
        "event_id" => to_string(online_event_id),
        "user_id" => to_string(user.id)
      })

      {:ok, _lv, html} =
        conn
        |> log_in_user(user_2)
        |> live(~p"/events/#{online_event}")

      assert html =~ "I will be there"
      refute html =~ "I changed my mind"

      lv
      |> element("button[phx-click=\"rsvp\"]")
      |> render_click(%{
        "event_id" => to_string(online_event_id),
        "user_id" => to_string(user_2.id)
      })

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/events/#{online_event}")

      refute html =~ "I will be there"
      assert html =~ "I changed my mind"
      assert html =~ "</a></li>"
      refute html =~ ">#{user_2.username}</a></li>"
      assert html =~ ">#{user_2.username}</li>"
      refute html =~ ">#{user.username}</li>"
    end

    test "clicking All events link leads back to events index page", %{
      conn: conn,
      user: user,
      online_event: online_event
    } do
      {:ok, lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/events/#{online_event}")

      assert html =~ "All Events"

      lv
      |> element(".text-gray-200", "All Events")
      |> render_click()

      assert_redirect(lv, ~p"/events")
    end

    test "redirects if user is not logged in", %{conn: conn, online_event: online_event} do
      assert {:error, redirect} = live(conn, ~p"/events/#{online_event}")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path === ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "leads back to index page if event does not exit", %{
      conn: conn,
      user: user,
      online_event: online_event
    } do
      online_event = Map.put(online_event, :id, online_event.id + 100)

      assert {:error,
              {:live_redirect,
               %{to: "/events", flash: %{"error" => "Something went wrong. Please try again"}}}} ===
               conn
               |> log_in_user(user)
               |> live(~p"/events/#{online_event}")
    end

    test "non_admin user would not be able to use the button to delete an event", %{
      conn: conn,
      user_2: user_2,
      online_event: online_event
    } do
      {:ok, lv, html} =
        conn
        |> log_in_user(user_2)
        |> live(~p"/events/#{online_event}")

      assert html =~ "meet.google"

      assert {:ok, ^online_event} = Content.find_event(%{id: online_event.id})

      assert lv
             |> element("button[phx-click=delete_event][phx-value-id='#{online_event.id}']")
             |> render_click() =~ "Could not delete event"

      assert {:ok, ^online_event} = Content.find_event(%{id: online_event.id})
    end

    test "shows delete and edit button to admin, admin can delete events and subscribers are notified",
         %{
           conn: conn,
           user: user,
           online_event: online_event
         } do
      assert {:ok, ^online_event} = Content.find_event(%{id: online_event.id})

      {:ok, lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/events/#{online_event}")

      assert html =~ "meet.google"
      assert html =~ "hero-trash"
      assert html =~ "Edit"

      lv
      |> element("button[phx-click=delete_event][phx-value-id='#{online_event.id}']")
      |> render_click()

      assert_email_sent()

      assert {
               :error,
               %ErrorMessage{
                 code: :not_found,
                 message: "no records found"
               }
             } = Content.find_event(%{id: online_event.id})
    end

    test "does not show the delete and edit button to non-admin users", %{
      conn: conn,
      user_2: user_2,
      online_event: online_event
    } do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user_2)
        |> live(~p"/events/#{online_event}")

      assert html =~ "meet.google"
      refute html =~ "hero-trash"
      refute html =~ "Edit"
    end
  end
end
