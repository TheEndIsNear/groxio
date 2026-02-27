defmodule Cardgames.CardTest do
  use ExUnit.Case, async: true
  alias Cardgames.Card

  test "new/2 creates a card struct with suit and value" do
    card = Card.new(:hearts, :ace)
    assert %Card{suit: :hearts, value: :ace} = card
  end

  test "show/1 prints hearts ace as ❤️A" do
    card = %Card{suit: :hearts, value: :ace}
    assert Card.show(card) == "❤️A"
  end

  test "show/1 prints spades ten as ♠️10" do
    card = %Card{suit: :spades, value: :ten}
    assert Card.show(card) == "♠️10"
  end

  test "show/1 prints face cards correctly" do
    jack = %Card{suit: :clubs, value: :jack}
    queen = %Card{suit: :diamonds, value: :queen}
    king = %Card{suit: :spades, value: :king}

    assert Card.show(jack) == "♣️J"
    assert Card.show(queen) == "♦️Q"
    assert Card.show(king) == "♠️K"
  end

  test "show/1 prints numeric ranks correctly" do
    five = %Card{suit: :clubs, value: :five}
    ten = %Card{suit: :hearts, value: :ten}

    assert Card.show(five) == "♣️5"
    assert Card.show(ten) == "❤️10"
  end
end
