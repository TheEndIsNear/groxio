defmodule Cardgames.Card do
    alias Cardgames.Card
    @moduledoc """
    A module for representing a card in a card game.

    The card is going to have a suit, in order based on Bridge rules from:
    - :spades
    - :hearts
    - :diamonds
    - :clubs

    And a value depending on the game where the defaults are:
    - :ace
    - :two
    - :three
    - :four
    - :five
    - :six
    - :seven
    - :eight
    - :nine
    - :ten
    - :jack
    - :queen
    - :king

    We'll attach possible ranking to the card based on the game.
    """

    defstruct [:suit, :value]

    @doc """
    Construct a card with the given suit and value.
    """
    def new(suit, value) do
        %Card{ suit: suit, value: value }
    end

    @doc """
    Shows a card based on the suit and value using an emoji for the suit and a character or number for the value.

    So a show of the card %Card{ suit: :hearts, value: :ace } would return "❤️A"
    """
    def show(%Card{ suit: suit, value: value }) do
        suit_emoji = suit_emoji(suit)
        value_str = value_char(value)

        "#{suit_emoji}#{value_str}"
    end

    defp suit_emoji(suit) do
        case suit do
            :spades -> "♠️"
            :hearts -> "❤️"
            :diamonds -> "♦️"
            :clubs -> "♣️"
        end
    end

    defp value_char(value) do
        case value do
            :ace -> "A"
            :two -> "2"
            :three -> "3"
            :four -> "4"
            :five -> "5"
            :six -> "6"
            :seven -> "7"
            :eight -> "8"
            :nine -> "9"
            :ten -> "10"
            :jack -> "J"
            :queen -> "Q"
            :king -> "K"
        end
    end
end
