![logo](https://i.imgur.com/UxMU0YW.png)

[![julia-version](https://img.shields.io/badge/julia_version-v1.6-9558B2?style=flat&logo=julia)](https://julialang.org/)
[![package-version](https://img.shields.io/badge/package_version-v1.0.0-9558B2?style=flat)](https://github.com/Paolo97Gll/Raytracer.jl/releases)
[![status](https://img.shields.io/badge/project_status-stable-green?style=flat)](https://github.com/Paolo97Gll/Raytracer.jl)
[![doc-stable](https://img.shields.io/badge/docs-stable-blue?style=flat)](https://paolo97gll.github.io/Raytracer.jl/stable)
[![doc-dev](https://img.shields.io/badge/docs-dev-blue?style=flat)](https://paolo97gll.github.io/Raytracer.jl/dev)

Raytracing package for the generation of photorealistic images in Julia.

Julia version required: ≥1.6

_Note: we refer to **stable** documentation for the latest tag, and **dev** documentation for the current code in the master branch._

- [Brief description](#brief-description)
- [Package and CLI tool](#package-and-cli-tool)
- [SceneLang](#scenelang)
- [Contributing](#contributing)
- [License](#license)

## Brief description

The main purpose of this package is to generate photorealistic images given an input scene.

The input scene is composed by a list of shapes (spheres, planes, ...) of various materials (for now diffusive or reflective) with different colors, each one with in a particular position in the 3D space. The observer is represented by a camera, that can do a perspective or an orthogonal projection. The camera will see the scene through a screen, characterized by its aspect ratio, distance from the camera and resolution. The image can be rendered with different [backwards ray tracing](https://en.wikipedia.org/wiki/Ray_tracing_(graphics)#Reversed_direction_of_traversal_of_scene_by_the_rays) algorithms: a [path tracer](https://en.wikipedia.org/wiki/Path_tracing) (the default renderer), a point-light tracer, a flat renderer and an on-off renderer; this process can be parallelized using multiple threads. Each of these aspects can be managed, tuned and modified using the low-level API of the package (see [below](#-Package-and-CLI-tool)).

There are two main steps in the image generation. We offer high-level API and a CLI tool (see [below](#package-and-cli-tool)) for these steps.

- The _generation of an HDR (high dynamic range) image_ in the [PFM format](http://www.pauldebevec.com/Research/HDR/PFM/). In this step, the scene is loaded along with the informations about the observer (position, orientation, type of the camera, ...) and the choosen renderer. Then the image is rendered using the choosen algorithm.

- The _conversion of this image to an LDR (low dynamic range) image_, such as jpg or png, using a [tone mapping](https://en.wikipedia.org/wiki/Tone_mapping) process.

Scenes can be defined using SceneLang (see [below](#scenelang)).

## Package and CLI tool

We provide:

- A package with both [high-level](https://paolo97gll.github.io/Raytracer.jl/stable/api/high-level) and [low-level](https://paolo97gll.github.io/Raytracer.jl/stable/api/low-level) API. It's possible to use the package's features directly from the REPL or in more complex scripts. See [quickstart](https://paolo97gll.github.io/Raytracer.jl/stable/quickstart/api).

- A [CLI tool](https://paolo97gll.github.io/Raytracer.jl/stable/cli). Thanks to the simple usage and the extended help messages, it makes possible the use of this package's high-level features to those who do not know Julia lang. See [quickstart](https://paolo97gll.github.io/Raytracer.jl/stable/quickstart/cli).

## SceneLang

[SceneLang](https://paolo97gll.github.io/Raytracer.jl/stable/scenelang) is a Domain-Specific Language (DSL) used to describe a 3D scene that can be rendered by Raytracer. See [quickstart](https://paolo97gll.github.io/Raytracer.jl/stable/quickstart/scenelang).

Being a DSL, SceneLang lacks some of the basic features of general purpose languages: there are no functions or custom types or even flexible arithmetic operations. SceneLang is made only to construct scenes to be rendered.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change. Please make sure to update tests as appropriate.

See contributing instructions [here](https://paolo97gll.github.io/Raytracer.jl/stable/devs/collab).

## License

The code is released under an MIT license. See the file [LICENSE.md](./LICENSE.md).
