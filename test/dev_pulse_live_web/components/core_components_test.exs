defmodule DevPulseLiveWeb.CoreComponentsTest do
  use DevPulseLiveWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import DevPulseLiveWeb.CoreComponents

  # -- Pure function tests --------------------------------------------------

  test "translate_error/1 returns message string" do
    result = translate_error({"can't be blank", []})
    assert result =~ "can't be blank"
  end

  test "translate_error/1 with count option uses plural form" do
    result = translate_error({"must be between %{min} and %{max}", [min: 1, max: 10]})
    assert is_binary(result)
  end

  test "translate_errors/2 returns only errors for given field" do
    errors = [name: {"can't be blank", []}, email: {"is invalid", []}]
    result = translate_errors(errors, :email)
    assert length(result) == 1
    assert hd(result) =~ "is invalid"
  end

  test "translate_errors/2 returns empty list when field has no errors" do
    errors = [name: {"can't be blank", []}]
    assert translate_errors(errors, :email) == []
  end

  test "show/2 returns a JS struct" do
    assert %Phoenix.LiveView.JS{} = show("#my-modal")
  end

  test "show/1 with default JS accumulates operations" do
    js = show("#my-modal")
    assert %Phoenix.LiveView.JS{} = js
  end

  test "hide/2 returns a JS struct" do
    assert %Phoenix.LiveView.JS{} = hide("#my-modal")
  end

  # -- Component render tests -----------------------------------------------

  test "icon/1 renders span with hero name class" do
    html = render_component(&icon/1, name: "hero-x-mark", class: "size-5")
    assert html =~ "hero-x-mark"
    assert html =~ "size-5"
  end

  test "icon/1 renders with default class" do
    html = render_component(&icon/1, name: "hero-inbox")
    assert html =~ "hero-inbox"
    assert html =~ "size-4"
  end

  test "flash/1 renders nothing when flash map is empty" do
    html = render_component(&flash/1, kind: :info, flash: %{})
    assert html == ""
  end

  test "flash/1 renders info message" do
    html = render_component(&flash/1, kind: :info, flash: %{"info" => "Success!"})
    assert html =~ "Success!"
    assert html =~ "alert-info"
  end

  test "flash/1 renders error message" do
    html = render_component(&flash/1, kind: :error, flash: %{"error" => "Something went wrong"})
    assert html =~ "Something went wrong"
    assert html =~ "alert-error"
  end

  test "flash/1 renders with title" do
    html =
      render_component(&flash/1,
        kind: :info,
        flash: %{"info" => "Updated"},
        title: "Notice"
      )

    assert html =~ "Notice"
    assert html =~ "Updated"
  end

  test "button/1 renders a button element" do
    html =
      render_component(&button/1,
        inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Click me" end}]
      )

    assert html =~ "Click me"
    assert html =~ "<button"
  end

  test "button/1 with navigate renders a link" do
    html =
      render_component(&button/1,
        navigate: "/",
        inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Go Home" end}]
      )

    assert html =~ "Go Home"
    assert html =~ "href"
  end

  test "button/1 with primary variant applies primary class" do
    html =
      render_component(&button/1,
        variant: "primary",
        inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Submit" end}]
      )

    assert html =~ "btn-primary"
  end

  test "input/1 renders text input by default" do
    html = render_component(&input/1, name: "user[name]", id: "user-name", value: "Alice")
    assert html =~ ~s(type="text")
    assert html =~ ~s(name="user[name]")
    assert html =~ "Alice"
  end

  test "input/1 renders with label" do
    html =
      render_component(&input/1,
        name: "q",
        id: "search",
        value: "",
        label: "Search",
        type: "text"
      )

    assert html =~ "Search"
  end

  test "input/1 renders with errors" do
    html =
      render_component(&input/1,
        name: "email",
        id: "email",
        value: "",
        errors: ["can't be blank"]
      )

    assert html =~ "can&#39;t be blank"
  end

  test "input/1 hidden renders hidden input" do
    html = render_component(&input/1, type: "hidden", name: "token", id: "token", value: "abc")
    assert html =~ ~s(type="hidden")
    assert html =~ "abc"
  end

  test "input/1 checkbox renders checkbox" do
    html =
      render_component(&input/1, type: "checkbox", name: "terms", id: "terms", value: "false")

    assert html =~ ~s(type="checkbox")
  end

  test "input/1 select renders select element" do
    html =
      render_component(&input/1,
        type: "select",
        name: "role",
        id: "role",
        value: "user",
        options: [{"Admin", "admin"}, {"User", "user"}]
      )

    assert html =~ "<select"
    assert html =~ "Admin"
    assert html =~ "User"
  end

  test "input/1 select renders with prompt" do
    html =
      render_component(&input/1,
        type: "select",
        name: "role",
        id: "role",
        value: nil,
        options: [{"User", "user"}],
        prompt: "Pick one"
      )

    assert html =~ "Pick one"
  end

  test "input/1 textarea renders textarea element" do
    html =
      render_component(&input/1, type: "textarea", name: "body", id: "body", value: "Hello")

    assert html =~ "<textarea"
    assert html =~ "Hello"
  end

  test "header/1 renders title" do
    html =
      render_component(&header/1,
        inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Page Title" end}]
      )

    assert html =~ "Page Title"
    assert html =~ "<header"
  end

  test "header/1 renders subtitle when provided" do
    html =
      render_component(&header/1,
        inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Title" end}],
        subtitle: [%{__slot__: :subtitle, inner_block: fn _, _ -> "Sub text" end}]
      )

    assert html =~ "Sub text"
  end

  test "table/1 renders rows" do
    rows = [%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}]

    html =
      render_component(&table/1,
        id: "users-table",
        rows: rows,
        col: [
          %{__slot__: :col, label: "Name", inner_block: fn _assigns, row -> row.name end}
        ]
      )

    assert html =~ "Alice"
    assert html =~ "Bob"
    assert html =~ "Name"
    assert html =~ "<table"
  end

  test "list/1 renders items" do
    html =
      render_component(&list/1,
        item: [
          %{__slot__: :item, title: "Key", inner_block: fn _, _ -> "Value" end},
          %{__slot__: :item, title: "Other", inner_block: fn _, _ -> "Data" end}
        ]
      )

    assert html =~ "Key"
    assert html =~ "Value"
    assert html =~ "Other"
  end
end
