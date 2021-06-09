# Raytracer.jl

[![julia-version](https://img.shields.io/badge/julia_version-v1.6-9558B2?style=flat&logo=julia)](https://julialang.org/)
[![package-version](https://img.shields.io/badge/package_version-v0.2.0-9558B2?style=flat)](https://github.com/Paolo97Gll/Raytracer.jl/releases)
[![status](https://img.shields.io/badge/project_status-beta-ba8a11?style=flat)](https://github.com/Paolo97Gll/Raytracer.jl)
[![doc-stable](https://img.shields.io/badge/docs-stable-blue?style=flat)](https://paolo97gll.github.io/Raytracer.jl/stable)
[![doc-dev](https://img.shields.io/badge/docs-dev-blue?style=flat)](https://paolo97gll.github.io/Raytracer.jl/dev)

Raytracing package for the generation of photorealistic images in Julia.

Julia version required: ≥1.6

## Brief description

Coming soon!

## Package and CLI tool

We provide:

- A package with both high-level and low-level API. It's possible to use the package's features directly from the REPL or in more complex scripts. More informations: [latest release (stable)](https://paolo97gll.github.io/Raytracer.jl/stable/quickstart/api), [master branch (dev)](https://paolo97gll.github.io/Raytracer.jl/dev/quickstart/api).

- A CLI tool. Thanks to the simple usage and the extended help messages, it makes possible the use of this package's high-level features to those who do not know Julia lang. More informations: [latest release (stable)](https://paolo97gll.github.io/Raytracer.jl/stable/quickstart/cli), [master branch (dev)](https://paolo97gll.github.io/Raytracer.jl/dev/quickstart/cli).

## Contributing

To contribute to the package development, clone this repository:

```shell
git clone https://github.com/Paolo97Gll/Raytracer.jl.git
cd Raytracer.jl
```

Then open julia REPL and type the following commands to update your environment:

```julia
import Pkg
Pkg.activate(".")
Pkg.instantiate()
```

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

The code is released under an MIT license. See the file [LICENSE.md](./LICENSE.md).
