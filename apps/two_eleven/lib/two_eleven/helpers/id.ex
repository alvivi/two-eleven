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

  @emojis ~w(
   ð ð ð ðĨ ðŦ ðĶ ðĻ ðĩ ð ðĶ ðĶ§ ðķ ð ðĶŪ ð ðĐ ðš ðĶ ðĶ ðą ð ð ðĶ ðŊ ð ð
   ðī ð ðĶ ðĶ ðĶ ðĶŽ ðŪ ð ð ð ð· ð ð ð― ð ð ð ðŠ ðŦ ðĶ ðĶ ð ðĶĢ ðĶ ðĶ
   ð­ ð ð ðđ ð° ð ðŋïļ ðĶŦ ðĶ ðĶ ðŧ ðŧ ðĻ ðž ðĶĨ ðĶĶ ðĶĻ ðĶ ðĶĄ ðū ðĶ ð ð ðĢ ðĪ
   ðĨ ðĶ ð§ ðïļ ðĶ ðĶ ðĶĒ ðĶ ðĶĪ ðŠķ ðĶĐ ðĶ ðĶ ðļ ð ðĒ ðĶ ð ðē ð ðĶ ðĶ ðģ ð ðŽ
   ðĶ­ ð ð  ðĄ ðĶ ð ð ðŠļ ð ðĶ ð ð ð ðŠē ð ðĶ ðŠģ ð·ïļ ðļïļ ðĶ ðĶ ðŠ° ðŠą ðĶ  ð ðļ
   ðŪ ðŠ· ðĩïļ ðđ ðĨ ðš ðŧ ðž ð· ðą ðŠī ðē ðģ ðī ðĩ ðū ðŋ âïļ ð ð ð ð ðŠđ ðŠš ð ð° ðĶ
   ðĶ ðĶ ðĶ ð ð ð ð ðŠĻ ð ð ð ð ð ð ð ð ð ð ð ð âïļ ð ð â­ ð ð 
   âïļ â âïļ ðĪïļ ðĨïļ ðĶïļ ð§ïļ ðĻïļ ðĐïļ ðŠïļ ðŦïļ ðŽïļ ð âïļ â âĄ âïļ âïļ â âïļ ðĨ ð§ ð ð âĻ ð ð ðŦ§
  )

  @adjectives_length length(@adjectives)
  @emojis_length length(@emojis)
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
  @spec to_name(binary()) :: String.t()
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

  @doc "Converts an id into non unique emoji."
  @spec to_emoji(binary()) :: String.t()
  def to_emoji(id) do
    case to_integer(id) do
      {:ok, integer} -> Enum.at(@emojis, rem(integer, @emojis_length))
      :error -> "â ïļ"
    end
  end
end
