# Raytracer.jl

![julia-version][julia-version] ![status][status] ![package-version][package-version]

[julia-version]: https://img.shields.io/badge/julia_version-v1.6-9558B2?style=flat&logo=julia
[status]: https://img.shields.io/badge/project_status-work--in--progress-ba8a11?style=flat
[package-version]: https://img.shields.io/badge/package_version-0.1-blue?style=flat

Raytracing package for the generation of photorealistic images in Julia.

Julia version required: ≥1.6

🚧 _This is a work-in-progress project: it is not ready to use and much of the code has yet to be written. Usage instructions and examples will come in the near future as project development progresses._

## Table of Contents

- [Raytracer.jl](#raytracerjl)
  - [Table of Contents](#table-of-contents)
  - [Package](#package)
    - [Installation](#installation)
    - [Usage](#usage)
    - [Examples](#examples)
  - [Main application](#main-application)
    - [Installation](#installation-1)
    - [Usage](#usage-1)
      - [Command `generate`](#command-generate)
      - [Command `tonemapping`](#command-tonemapping)
    - [Examples](#examples-1)
      - [Generation of a photorealistic image](#generation-of-a-photorealistic-image)
      - [Tone mapping](#tone-mapping)
  - [Contributing](#contributing)
  - [License](#license)

## Package

### Installation

The package is still under development and is not available in the official registry. To add this package to your work environment, open julia and type the following commands:

```julia
import Pkg
Pkg.add(url="https://github.com/Samuele-Colombo/FileIO.jl")
Pkg.add(url="https://github.com/Samuele-Colombo/ImagePFM.jl")
Pkg.add(url="https://github.com/Paolo97Gll/Raytracer.jl")
```

We use a [custom version](https://github.com/Samuele-Colombo/FileIO.jl) of the FileIO package that provides load/save functionalities for pfm files: this integration is done by the package [ImagePFM](https://github.com/Samuele-Colombo/ImagePFM.jl). If FileIO is already present (e.g. the original package), it will be overwritten by this custom version.

### Usage

Coming soon!

### Examples

Coming soon!

## Main application

A command line tool `raytracer_cli.jl` is available to manage through this package the generation and rendering of photorealistic images.

### Installation

To use it, clone this repository:

```shell
git clone https://github.com/Paolo97Gll/Raytracer.jl.git
cd Raytracer.jl
```

Then open julia and type the following commands to update your environment:

```julia
import Pkg
Pkg.activate(".")
Pkg.instantiate()
```

### Usage

```text
$ julia raytracer_cli.jl --help

usage: raytracer_cli.jl [-h] {generate|tonemapping}

Raytracing for the generation of photorealistic images in Julia.

commands:
  generate     generate photorealistic image from input file
  tonemapping  apply tone mapping to a pfm image and save it to file

optional arguments:
  -h, --help   show this help message and exit
```

#### Command `generate`

Coming soon!

#### Command `tonemapping`

```text
$ julia raytracer_cli.jl tonemapping --help

usage: raytracer_cli.jl tonemapping [-a ALPHA] [-g GAMMA] [-h]
                        input_file output_file

Apply tone mapping to a pfm image and save it to file.

optional arguments:
  -h, --help         show this help message and exit

tonemapping settings:
  -a, --alpha ALPHA  scaling factor for the normalization process
                     (type: Float64, default: 0.5)
  -g, --gamma GAMMA  gamma value for the tone mapping process (type:
                     Float64, default: 1.0)

files:
  input_file         path to input file, it must be a PFM file
  output_file        output file name
```

We support as output image type all the formats supported by the packages [ImageIO](https://github.com/JuliaIO/ImageIO.jl), [ImageMagick](https://github.com/JuliaIO/ImageMagick.jl) and [QuartzImageIO](https://github.com/JuliaIO/QuartzImageIO.jl), including:

- jpg, jpeg
- png
- tif, tiff
- ppm
- bmp
- gif
- ...

### Examples

#### Generation of a photorealistic image

Coming soon!

#### Tone mapping

You can use the `tonemapping` command to apply the tone mapping process to a pfm image. For example, you can use the following command to convert the image `test/memorial.pfm` into a jpg image:

```shell
julia raytracer_cli.jl tonemapping test/memorial.pfm memorial.jpg
```

You can also change the default values of `alpha` and/or `gamma` to obtain a better tone mapping, according to your source image:

```shell
julia raytracer_cli.jl tonemapping --alpha 0.35 --gamma 1.3 test/memorial.pfm memorial.jpg
```

## Contributing

To contribute to package development, clone this repository:

```shell
git clone https://github.com/Paolo97Gll/Raytracer.jl.git
cd Raytracer.jl
```

Then open julia and type the following commands to update your environment:

```julia
import Pkg
Pkg.activate(".")
Pkg.instantiate()
```

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

The code is released under a MIT license. See the file [LICENSE.md](./LICENSE.md).
