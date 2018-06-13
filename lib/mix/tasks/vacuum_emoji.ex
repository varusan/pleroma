defmodule Mix.Tasks.VacuumEmoji do
  use Mix.Task

  @custom_emoji_dir "priv/static/emoji/custom/"
  @base_url "/emoji/custom/"

  @shortdoc "Vacuum emoji from instance"
  def run([instance_url]) do
    IO.puts("This task will add emoji from a given instance to your custom_emoji.txt file.")
    IO.puts("You will need to restart your server after running it.")
    IO.puts("Note: this script does not check for duplicates against your current emoji.")

    if IO.gets("Continue? (Ctrl-C to abort) ") do
      Application.ensure_all_started(:httpoison)

      with {:ok, %{body: body}} <-
             HTTPoison.get(URI.merge(instance_url, "/api/v1/custom_emojis") |> to_string),
           {:ok, list} <- Jason.decode(body) do
        File.mkdir_p(@custom_emoji_dir)

        new_emoji =
          list
          |> Enum.reject(fn %{"url" => url} ->
            # do not download any of the default ones
            Regex.match?(~r{/finmoji/}, url) || Regex.match?(~r{/f\_(0|1|2|3)}, url) ||
              Regex.match?(~r{/Firefox.gif}, url) || Regex.match?(~r{blank.png}, url)
          end)
          |> Enum.map(fn %{"shortcode" => shortcode, "url" => url} ->
            with {:ok, %{body: image}} <- HTTPoison.get(url) do
              %{path: rqpath} = URI.parse(url)
              location = Path.join(@custom_emoji_dir, Path.basename(rqpath))
              File.write!(location, image)
              IO.puts("#{shortcode} downloaded")
              "#{shortcode}, #{Path.join(@base_url, Path.basename(rqpath))}"
            else
              e ->
                IO.puts("Could not get emoji at #{url}, error:\n\t#{e}")
                nil
            end
          end)
          |> Enum.filter(& &1)
          |> Enum.join("\n")

        File.open("config/custom_emoji.txt", [:write, :append], fn file ->
          IO.write(file, "\n" <> new_emoji)
        end)

        IO.puts("\nVacuum complete!")
      end
    end
  end

  def run([]) do
    IO.puts("\n\tUsage:\n\n\t\tmix vacuum_emoji https://instance.tld")
  end
end
