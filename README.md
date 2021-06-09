# Raytracer.jl

[![julia-version](https://img.shields.io/badge/julia_version-v1.6-9558B2?style=flat&logo=julia)](https://julialang.org/)
[![package-version](https://img.shields.io/badge/package_version-v0.2.0-9558B2?style=flat)](https://github.com/Paolo97Gll/Raytracer.jl/releases)
[![status](https://img.shields.io/badge/project_status-beta-ba8a11?style=flat)]()
[![doc-stable](https://img.shields.io/badge/docs-stable-blue?style=flat)](https://paolo97gll.github.io/Raytracer.jl/stable)
[![doc-dev](https://img.shields.io/badge/docs-dev-blue?style=flat)](https://paolo97gll.github.io/Raytracer.jl/dev)

Raytracing package for the generation of photorealistic images in Julia.

Julia version required: ≥1.6

## Table of Contents

- [Raytracer.jl](#raytracerjl)
  - [Table of Contents](#table-of-contents)
  - [Package](#package)
  - [Command line tool](#command-line-tool)
  - [Contributing](#contributing)
  - [License](#license)

## Package

The package offer a series of API to manage the generation and rendering of a photorealistic image.

See documentation at: <https://paolo97gll.github.io/Raytracer.jl>

## Command line tool

A command line tool `raytracer_cli.jl` is available to use high-level API of the main package.

See documentation at: <https://paolo97gll.github.io/Raytracer.jl>

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
