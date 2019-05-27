defmodule FileConfig.Handler.CsvStream do
  require Lager

  def parse_file(path, table_id, config) do
    {k, v} = config[:csv_fields] || {1, 2}
    data_parser = config[:data_parser]
    lazy_parse = config[:lazy_parse]
    name = config[:name]

    success_count =
      File.stream!(path, [:utf8, :line])
      |> Enum.reduce(0, fn line, acc ->
        case load_line(line, table_id, {k, v}, data_parser, lazy_parse, name) do
          true ->
            acc + 1

          _ ->
            acc
        end
      end)

    {:ok, success_count}
  end

  def load_line(line, table_id, {k, v}, data_parser, lazy_parse, name) do
    list = String.split(line, "\t")
    len = length(list)
    key = Enum.at(list, k - 1)
    value = Enum.at(list, v - 1)

    maybe_parsed =
      case lazy_parse do
        true ->
          value

        _ ->
          data_parser.parse_value(name, key, value)
      end

    true = :ets.insert(table_id, {key, maybe_parsed})
  end
end
