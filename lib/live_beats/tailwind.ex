defmodule LiveBeats.Tailwind do
  def run(args) do
    opts = [
      cd: IO.inspect(Path.join(File.cwd!(), "assets")),
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true
    ]

    Path.expand("assets/tailwindcss-macos-x64")
    |> System.cmd(args, opts)
    |> elem(1)
  end
end
