# [CLI tool](@id cli_tool)

## Contents

```@contents
Pages = ["cli.md"]
Depth = 3
```

## Description

The CLI tool is named `raytracer_cli.jl` and is placed in the root of the repository. Thanks to the simple usage and the extended help messages, it makes possible the use of this package's high-level features to those who do not know Julia lang.

This CLI tool recalls functions already present in the `Raytracer.jl` module, so is possible to run almost all these commands also from the REPL, by calling the same functions called by the tool.

!!! note
    For now, the command [`render animation`](@ref raytracer_cli_render_animation) is available only with the CLI tool.

## Installation

See [CLI tool installation](@ref cli_tool_installation).

## Usage

!!! note
    You _must_ call this tool from the repo main folder! It will not work if called by another folder.

The CLI tool is based on a series of commands, in a similar way to the `git` and `docker` CLI tools. The menu tree is:

- [`raytracer_cli.jl`](@ref raytracer_cli)
  - [`render`](@ref raytracer_cli_render)
    - [`image`](@ref raytracer_cli_render_image)
    - [`animation`](@ref raytracer_cli_render_animation)
  - [`tonemapping`](@ref raytracer_cli_tonemapping)
  - [`docs`](@ref raytracer_cli_docs)

### [`raytracer_cli.jl`](@id raytracer_cli)

```text
usage: raytracer_cli.jl [--version] [-h] {render|tonemapping|docs}

Raytracing for the generation of photorealistic images in Julia.

commands:
  render       render an image from a SceneLang script
  tonemapping  apply tone mapping to a pfm image and save it to file
  docs         show the documentation link

optional arguments:
  --version    show version information and exit
  -h, --help   show this help message and exit
```

### [`raytracer_cli.jl render`](@id raytracer_cli_render)

```text
usage: raytracer_cli.jl render [--version] [-h] {image|animation}

Render an image from a SceneLang script.

commands:
  image       render an image from a SceneLang script
  animation   create an animation as mp4 video from a SceneLang script
              (require ffmpeg)

optional arguments:
  --version   show version information and exit
  -h, --help  show this help message and exit
```

### [`raytracer_cli.jl render image`](@id raytracer_cli_render_image)

```text
```

### [`raytracer_cli.jl render animation`](@id raytracer_cli_render_animation)

This is an advanced function that requires [ffmpeg](https://www.ffmpeg.org/) to be installed on the local machine and to be in the PATH. It generates an H.264 mp4 video containing the animation.

!!! note
    For now, the generation of animations is available only with the CLI tool.

```text
```

### [`raytracer_cli.jl tonemapping`](@id raytracer_cli_tonemapping)

!!! note
    We support as output image type all the formats supported by the packages [ImageIO](https://github.com/JuliaIO/ImageIO.jl), [ImageMagick](https://github.com/JuliaIO/ImageMagick.jl) and [QuartzImageIO](https://github.com/JuliaIO/QuartzImageIO.jl), including: jpg, png, tiff, ppm, bmp, gif, ...

```text
usage: raytracer_cli.jl tonemapping [-f] [-a ALPHA] [-g GAMMA]
                        [-l LUMINOSITY] [--version] [-h] input-file
                        output-file

Apply tone mapping to a pfm image and save it to file.

positional arguments:
  input-file            path to input file, it must be a PFM file
  output-file           output file name

optional arguments:
  -f, --force           force overwrite
  --version             show version information and exit
  -h, --help            show this help message and exit

tonemapping settings:
  -a, --alpha ALPHA     scaling factor for the normalization process
                        (type: Float32, default: 0.5)
  -g, --gamma GAMMA     gamma value for the tone mapping process
                        (type: Float32, default: 1.0)
  -l, --luminosity LUMINOSITY
                        luminosity for the tone mapping process (type:
                        Union{Nothing, Float32})
```

### [`raytracer_cli.jl docs`](@id raytracer_cli_docs)

```text
usage: raytracer_cli.jl docs [--dev] [--version] [-h]

Show the documentation link.

optional arguments:
  --dev       documentation of the dev version
  --version   show version information and exit
  -h, --help  show this help message and exit
```

## Multithreading

To enable multithreading, e.g. use 8 threads, add `-t num_threads` after the `julia` command:

```shell
julia -t 8 raytracer_cli.jl demo image
```

Here all examples use only one thread, but you can specify the number of threads you prefer.

## Examples

### Tone mapping

You can use the [`tonemapping`](@ref raytracer_cli_tonemapping) ray command to apply the tone mapping process to a pfm image. For example, you can use the following command to convert the image `test/memorial.pfm` into a jpg image:

```shell
julia raytracer_cli.jl tonemapping test/memorial.pfm memorial.jpg
```

![](https://i.imgur.com/YX9eSkk.jpg)

You can also convert to a png image:

```shell
julia raytracer_cli.jl tonemapping test/memorial.pfm memorial.png
```

or any other format supported (see [here](@ref raytracer_cli_tonemapping)).

You can also change the default values of `alpha` and/or `gamma` to obtain a better tone mapping, according to your source image:

```shell
julia raytracer_cli.jl tonemapping --alpha 0.2 --gamma 1.8 test/memorial.pfm memorial.jpg
```

![](https://i.imgur.com/c6tKSRG.jpg)

### Generate a demo image

You can use the [`demo image`](@ref raytracer_cli_render_image) command to render a demo image:

```shell
julia raytracer_cli.jl demo image
```

![](https://i.imgur.com/DiYwNyG.jpg)

It creates two files: `demo.pfm` (the HDR image) and `demo.jpg` (the LDR image).

You can change the output file name, the LDR extension and other rendering parameters using the command options. For example, you can enable antialiasing and see the difference it can make. Here an example with 36 rays/pixel:

![](https://i.imgur.com/8JCWIJ2.jpg)

### Generate a demo animation

To create a demo animation, use the command [`demo animation`](@ref raytracer_cli_render_animation):

```shell
julia raytracer_cli.jl demo animation
```

```@raw html
<video autoplay="" controls="" loop="" width="540" height="540">
  <source src="https://i.imgur.com/2yEoRbA.mp4">
</video>
```

It creates a new folder `demo_animation` with the video `demo.mp4` and all the frames in jpeg format.

You can change the output folder and file name and other rendering and animation parameters using the command options.
