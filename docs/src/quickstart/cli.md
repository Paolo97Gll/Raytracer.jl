# Basic CLI tool usage

The CLI tool is named `raytracer_cli.jl` and is placed in the root of the repository.

The usage is based on a series of commands, in a similar way to the `git` and `docker` CLI tools:

```shell
julia raytracer_cli.jl {command} [{subcommand}] [options]
```

For example, to apply the tonemapping process you can use:

```shell
julia raytracer_cli.jl tonemapping [options] input_file.pfm output_file.<LDR_extension>
```
where `LDR_extension` indicates the desired output format. Most LDR formats are supported (see [tonemapping](@ref raytracer_cli_tonemapping)).

Related commands are encapsulated, like the `demo` command: it admits a set of subcommands that specify the type of demo.

```shell
julia raytracer_cli.jl demo image
```

```shell
julia raytracer_cli.jl demo animation
```

More informations [here](@ref cli_tool).
