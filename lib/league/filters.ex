defmodule League.Filters do
  @moduledoc """
  Fuzzy match scorer for strings against a search pattern.
  """

  # The point modifiers that determine the final fuzzy match score.
  @points %{
    # The number of points each potential match starts with.
    starting: 100,
    bonuses: %{
      # Bonus points if the first letter of the string == the first letter of the pattern.
      # For the pattern "test", "TESTers" will score higher than "proTEST".
      first_letter: 15,
      ## Bonus points for sequential matching characters. For the pattern "can", the string
      ## "she sCANs" will score higher than "aCre lAwN".
      sequential: 15,
      ## Bonus points for characters that occur after a space. For the pattern "si", the string
      ## "Select Item" will score higher than "Select pIns"
      separator: 30
    },
    penalties: %{
      ## Penalty for each character before the match starts. For the pattern "red", the string
      ## "tiRED" will have at least (2 * -5) == -10 penalty points.
      unmatched_leading: -5,
      ## The max number of penalty points for the above.
      max_unmatched_leading: -15,
      ## Penalty for every character in the string that is not in the pattern. For the pattern
      ## "cod", the string "CODecs" will have at least (3 * -1) == -3 penalty points.
      unmatched: -1
    }
  }

  @doc """
  Fuzzy matches the pattern against the string.

  Returns the string indexes at which the pattern graphemes are found within the string, as well as
  a "match score". If there are multiple possible match combinations within the string, the one
  with the highest "match score" will be returned.

  ## Examples

      iex> League.Filters.fuzzy_match("af", "All Fin AF")
      {[0, 4], 137}
  """
  def fuzzy_match(pattern, string) do
    matching_graphemes = find_matching_graphemes(pattern, string)

    if Enum.any?(matching_graphemes) do
      matching_graphemes
      |> Enum.map(&{&1, calculate_match_score(&1, string)})
      |> Enum.max_by(fn {_, score} -> score end)
    else
      {[], 0}
    end
  end

  @doc """
  Finds the indexes at which the pattern graphemes are found within the string. This will return
  every combination of applicable indexes.

  ## Examples

      iex> League.Filters.find_matching_graphemes("af", "All Fin AF")
      [[0, 4], [8, 9], [0, 9]]
  """
  def find_matching_graphemes(pattern, string) do
    Enum.map(
      do_find_matching_graphemes(
        String.graphemes(pattern),
        String.graphemes(string),
        0,
        String.length(pattern),
        [],
        []
      ),
      &Enum.reverse/1
    )
  end

  defp do_find_matching_graphemes(
         [],
         _string,
         _string_index,
         pattern_length,
         matching_indexes,
         other_matching_indexes
       ) do
    clean_matching_indexes(pattern_length, matching_indexes, other_matching_indexes)
  end

  defp do_find_matching_graphemes(
         _pattern,
         [],
         _string_index,
         pattern_length,
         matching_indexes,
         other_matching_indexes
       ) do
    clean_matching_indexes(pattern_length, matching_indexes, other_matching_indexes)
  end

  defp do_find_matching_graphemes(
         pattern,
         string,
         string_index,
         pattern_length,
         matching_indexes,
         other_matching_indexes
       ) do
    pattern_grapheme = hd(pattern)
    [string_grapheme | string] = string

    {pattern, matching_indexes, new_matching_indexes} =
      if String.downcase(pattern_grapheme) == String.downcase(string_grapheme) do
        {
          tl(pattern),
          [string_index | matching_indexes],
          # There might be a different substring that produces a higher score if we skip this
          # current matched character. Let's try out those possibilities.
          do_find_matching_graphemes(
            pattern,
            string,
            string_index + 1,
            pattern_length,
            matching_indexes,
            []
          )
        }
      else
        {pattern, matching_indexes, []}
      end

    do_find_matching_graphemes(
      pattern,
      string,
      string_index + 1,
      pattern_length,
      matching_indexes,
      other_matching_indexes ++ new_matching_indexes
    )
  end

  defp clean_matching_indexes(0, _matching_indexes, _other_matching_indexes), do: []

  defp clean_matching_indexes(pattern_length, matching_indexes, other_matching_indexes) do
    for indexes <- [matching_indexes | other_matching_indexes],
        Enum.count(indexes) == pattern_length do
      indexes
    end
  end

  defp calculate_match_score([], _string), do: 0
  defp calculate_match_score(_matching_indexes, ""), do: 0

  defp calculate_match_score(matching_indexes, string) do
    score =
      @points.starting +
        @points.penalties.unmatched * (String.length(string) - Enum.count(matching_indexes)) +
        max(
          @points.penalties.unmatched_leading * hd(matching_indexes),
          @points.penalties.max_unmatched_leading
        )

    {score, _} =
      Enum.reduce(matching_indexes, {score, nil}, fn index, {score, prev_index} ->
        # TODO: Apply a multiplier for longer sequences. For example, with the pattern "exit",
        #   the string "EXIT here" will get a sequence bonus of 45, while the string
        #   "EXample unIT" will get a sequence bonus of 30. The former should score much higher
        #   than the latter.
        score =
          if prev_index && prev_index + 1 == index do
            score + @points.bonuses.sequential
          else
            score
          end

        score =
          cond do
            index == 0 -> score + @points.bonuses.first_letter
            String.at(string, index - 1) == " " -> score + @points.bonuses.separator
            true -> score
          end

        {score, index}
      end)

    score
  end

  @doc """
  Gets the points map used to calculate the match score.
  """
  def get_points, do: @points
end
