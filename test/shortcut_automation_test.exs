defmodule ShortcutAutomationTest do
  use ExUnit.Case
  doctest ShortcutAutomation

  test "greets the world" do
    assert ShortcutAutomation.hello() == :world
  end
end
