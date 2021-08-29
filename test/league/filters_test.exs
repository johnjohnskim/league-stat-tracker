defmodule League.FiltersTest do
  use ExUnit.Case

  alias League.Filters

  doctest League.Filters

  test "chooses better substring match" do
    points = Filters.get_points()

    # This should match the "l"s in "let" and "llamas", not "eli".
    assert Filters.fuzzy_match("lll", "let eli's llamas play") ==
             {[0, 10, 11],
              points.starting +
                points.bonuses.first_letter +
                points.bonuses.sequential +
                points.bonuses.separator +
                points.penalties.unmatched * 18}
  end

  test "handles no match" do
    assert Filters.fuzzy_match("nope", "yesyup") == {[], 0}
  end

  test "finds matching graphemes" do
    assert Filters.find_matching_graphemes("af", "All Fin AF") == [[0, 4], [8, 9], [0, 9]]
  end

  test "ignores empty strings" do
    assert Filters.find_matching_graphemes("", "test") == []
    assert Filters.find_matching_graphemes("test", "") == []
  end

  test "handles no matching graphemes" do
    assert Filters.find_matching_graphemes("nope", "yesyup") == []
  end
end
