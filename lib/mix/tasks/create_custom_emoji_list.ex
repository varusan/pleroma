defmodule Mix.Tasks.CreateCustomEmojiList do
  use Mix.Task

  @emoji_root "priv/static/emoji/"
  @custom_emoji_root "#{@emoji_root}custom"
  @custom_emoji_file "config/custom_emoji.txt"

  @shortdoc "Generates #{@custom_emoji_file}"
  def run(_) do
    if File.dir?(@custom_emoji_root) do
      IO.puts("#{@custom_emoji_root} directory found.")
      {:ok, file_handle} = File.open(@custom_emoji_file, [:write])
      handle_dir(@custom_emoji_root, file_handle)
      File.close(file_handle)
    else
      IO.puts("#{@custom_emoji_root} directory does not exist.")
    end
  end

  def handle_dir(dir, file_handle) do
    for entry <- File.ls!(dir) do
      full_entry_path = Path.join(dir, entry)

      if File.dir?(full_entry_path) do
        handle_dir(full_entry_path, file_handle)
      else
        handle_file(full_entry_path, file_handle)
      end
    end
  end

  def handle_file(file, file_handle) do
    relative_name = Path.relative_to(file, @emoji_root)
    basename = String.downcase(Path.basename(file, Path.extname(file)))
    IO.puts(file_handle, "#{basename}, /emoji/#{relative_name}")
  end
end
