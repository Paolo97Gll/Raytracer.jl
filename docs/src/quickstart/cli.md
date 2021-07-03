# Basic CLI tool usage

The CLI tool is named `raytracer_cli.jl` and is placed in the root of the repository.

The usage is based on a series of commands, in a similar way to the `git` and `docker` CLI tools:

```shell
julia raytracer_cli.jl {command} [{subcommand}] [options]
```

To apply the tone mapping process to a pfm image you can use:

```shell
julia raytracer_cli.jl tonemapping input-file.pfm output-file.<ldr-extension> [options]
```

where `ldr-extension` indicates the desired output format. Most LDR formats are supported (see [tonemapping](@ref raytracer_cli_tonemapping)).

The command `render` admits a set of subcommands that specify the type of rendering (image or animation). You need to specify a SceneLang input script.

```shell
julia raytracer_cli.jl render image input-script.sl [options]
```

```shell
julia raytracer_cli.jl render animation input-script.sl [animation parameters] [options]
```

More informations and examples [here](@ref cli_tool).
