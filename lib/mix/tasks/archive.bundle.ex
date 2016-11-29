defmodule Mix.Tasks.Archive.Bundle do
  # mix task
  use Mix.Task

  # information for the mix command line
  @shortdoc "Archives this project (with deps) into an .ez file"

  @moduledoc """
  Wrapper around `Mix.Tasks.Archive.Build` to bundle in any Mix dependencies.

  The same arguments are accepted (as it stands in Elixir v1.3), and they'll work
  in the same way as this task bundles before calling the usual build task. If
  you specify the `-i` flag, it will be ignored as it's used internally to carry
  out the bundling - but you won't need it if you're using this task anyway.

  The only major difference is that this must be run from inside a Mix project,
  but again, this task would be pointless if is wasn't being.

  ## Command line options

    * `-o` - specifies output file name.
      If there is a `mix.exs`, defaults to "APP-VERSION.ez".

    * `--no-compile` - skips compilation.

  """
  @spec run(OptionParser.argv) :: :ok
  def run(args) do
    # ensure project
    Mix.Project.get!()

    # compile as appropriate
    unless "--no-compile" in args do
      Mix.Task.run("compile", args)
    end

    # generate various directory paths
    tmp = generate_dir()
    out = Mix.Project.build_path()
    lib = Path.join(out, "lib")

    # run everything from within lib
    File.cd!(lib, fn ->

      # search for all ebin and priv files
      ebin = Path.wildcard("**/ebin/*.{beam,app}") |> IO.inspect
      priv = Path.wildcard("**/priv/**/*") |> IO.inspect

      # map the files to their copy path
      pairs = Enum.map(ebin ++ priv, fn(file) ->
        # remove the top level path (the module name)
        [ _module | segments ] = Path.split(file)

        # join up the remaining segments
        relative = Enum.join(segments, "/")
        location = Path.join(tmp, relative)

        # return our tuple
        { file, location }
      end)

      # count the number of files set for each destination
      group = Enum.reduce(pairs, %{ }, fn({ file, location }, groups) ->
        # add the file against the location group
        Map.update(groups, location, [ file ], &([ file | &1 ]))
      end)

      # calculate any duplicate destinations
      clash = Enum.reduce(group, [], fn({ location, files }, clashes) ->
        # verify clash count
        case files do
          # no clashes, just return
          [_] -> clashes
          # process clashes
          val ->
            # pull back the modules causing clashes
            module = Enum.map(files, &get_module_from_path/1)
            # pull back the file name of that's clashing
            suffix = String.trim_leading(location, tmp)
            # add the tuple to the output message
            [ inspect({ suffix, module }) | clashes ]
        end
      end)

      # exit if there are any clashes
      unless Enum.empty?(clash) do
        # raise an error containing the clashing files
        Mix.raise("Unable to bundle due to file clashes:\n\n" <>
                  "#{Enum.join(clash, "\n")}")
      end

      # copy all of our pairs
      Enum.each(pairs, fn({ file, location }) ->
        # make sure the directory exists
        location
        |> Path.dirname
        |> File.mkdir_p!

        # copy the file to the location
        File.cp!(file, location)
      end)
    end)

    # execute the usual build task with our input dir, and avoid compiling twice
    Mix.Task.run("archive.build", [ "-i", tmp, "--no-compile" ] ++ args)

    # remove the tmp directory
    File.rm_rf!(tmp)
  end

  # Generates a temporary directory for this build by creating a directory with
  # a unique suffix in a temp directory and returning the created path.
  defp generate_dir do
    tmp = System.tmp_dir!()
    dir = Path.join(tmp, "bundle-#{generate_id()}")
    File.mkdir!(dir)
    dir
  end

  # Generates a unique hex id using the `:crypto` module. From there we convert
  # it over to hex and slice the first 16 characters (no point having long names).
  defp generate_id do
    16
    |> :crypto.strong_rand_bytes
    |> Base.encode16([ case: :lower ])
    |> String.slice(0..16)
  end

  # Pops the top level of a path, returning the module name.
  defp get_module_from_path(path) do
    path
    |> Path.split
    |> List.first
  end

end
