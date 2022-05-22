defmodule TwoEleven.Helpers.Id do
  @moduledoc """
  Simple identifiers for simple scenarios.

  Based on
  [gen_reference](https://dreamconception.com/tech/elixir-simple-way-to-create-random-reference-ids/)
  and https://gist.github.com/coryodaniel/d5e8fa15b3d1fe566b3c3f821225936e.
  """

  @base 36
  @min String.to_integer("100000", @base)
  @max String.to_integer("ZZZZZZ", @base)

  @adjectives ~w(
    autumn hidden bitter misty silent empty dry dark summer
    icy delicate quiet white cool spring winter patient
    twilight dawn crimson wispy weathered blue billowing
    broken cold damp falling frosty green long late lingering
    bold little morning muddy old red rough still small
    sparkling throbbing shy wandering withered wild black
    young holy solitary fragrant aged snowy proud floral
    restless divine polished ancient purple lively nameless
  )

  @nouns ~w(
    waterfall river breeze moon rain wind sea morning
    snow lake sunset pine shadow leaf dawn glitter forest
    hill cloud meadow sun glade bird brook butterfly
    bush dew dust field fire flower firefly feather grass
    haze mountain night pond darkness snowflake silence
    sound sky shape surf thunder violet water wildflower
    wave water resonance sun wood dream cherry tree fog
    frost voice paper frog smoke star hamster
  )

  @adjectives_length length(@adjectives)
  @nouns_length length(@nouns)

  @doc "Creates a slightly unique binary identifier."
  @spec new :: binary()
  def new, do: Integer.to_string(@min + :rand.uniform(@max - @min), @base)

  @doc "Converts a binary identifier into an `t:integer/0`."
  @spec to_integer(binary()) :: {:ok, integer()} | :error
  def to_integer(id) do
    case Integer.parse(id, @base) do
      {integer, ""} -> {:ok, integer}
      _error_or_trailing_chars -> :error
    end
  end

  @doc "Converts an id into non unique, adjective/noun string."
  def to_name(id) do
    case to_integer(id) do
      {:ok, integer} ->
        third = div(integer, 3)
        adjective = Enum.at(@adjectives, rem(third * 2, @adjectives_length))
        noun = Enum.at(@nouns, rem(third, @nouns_length))

        "#{adjective}-#{noun}"

      :error ->
        "inspiring-hacker"
    end
  end
end
