![logo](https://i.imgur.com/UxMU0YW.png)

Raytracing package for the generation of photorealistic images in Julia.

## Contents

```@contents
Pages = ["index.md"]
Depth = 3
```

## Brief description

The main purpose of this package is to generate photorealistic images given an input scene.

The input scene is composed by a list of shapes (spheres, planes, ...) of various materials (for now diffusive or reflective) with different colors, each one with in a particular position in the 3D space. The observer is represented by a camera, that can do a perspective or an orthogonal projection. The camera will see the scene through a screen, characterized by its aspect ratio, distance from the camera and resolution. The image can be rendered with different [backwards ray tracing](https://en.wikipedia.org/wiki/Ray_tracing_(graphics)#Reversed_direction_of_traversal_of_scene_by_the_rays) algorithms: a [path tracer](https://en.wikipedia.org/wiki/Path_tracing) (the default renderer), a point-light tracer, a flat renderer and an on-off renderer; this process can be parallelized using multiple threads. Each of these aspects can be managed, tuned and modified using the low-level API of the package (see below).

There are two main steps in the image generation. We offer high-level API and a CLI tool for these steps (see below).

- The _generation of an HDR (high dynamic range) image_ in the [PFM format](http://www.pauldebevec.com/Research/HDR/PFM/). In this step, the scene is loaded along with the informations about the observer (position, orientation, type of the camera, ...) and the chosen renderer. Then the image is rendered using the chosen algorithm.

- The _conversion of this image to an LDR (low dynamic range) image_, such as jpg or png, using a [tone mapping](https://en.wikipedia.org/wiki/Tone_mapping) process.

## Overview

We provide:

- A package with both [high-level API](@ref high_level_api) and [low-level API](@ref low_level_api). It's possible to use the package's features directly from the REPL or in more complex scripts. See [Basic API usage](@ref).

- A [CLI tool](@ref cli_tool). Thanks to the simple usage and the extended help messages, it makes possible the use of this package's high-level features to those who do not know Julia lang. See [Basic CLI tool usage](@ref).

- [SceneLang](@ref scenelang) is a Domain-Specific Language (DSL) used to describe a 3D scene that can be rendered by Raytracer. Being a DSL, SceneLang lacks some of the basic features of general purpose languages: there are no functions or custom types or even flexible arithmetic operations. SceneLang is made only to construct scenes to be rendered. See [Basic SceneLang usage](@ref).

For example, to generate an image from a SceneLang script, you can use the julia REPL:

```julia-repl
julia> using Raytracer

julia> render_from_script("path/to/script.sl")
```

or equivalently the CLI tool:

```text
~/Raytracer.jl❯ julia raytracer_cli.jl render image path/to/script.sl
```

The CLI tool has more advanced features, like the generation of animations, but using the package from the REPL gives more flexibility.

## Installation

### Package

The package is not available in the official registry.

To add this package to your main environment (_not recommended_), open the julia REPL and type the following commands:

```julia
import Pkg
Pkg.add(url="https://github.com/Samuele-Colombo/FileIO.jl")
Pkg.add(url="https://github.com/Samuele-Colombo/ImagePFM.jl")
Pkg.add(url="https://github.com/Paolo97Gll/Raytracer.jl")
```

We use a [custom version of FileIO](https://github.com/Samuele-Colombo/FileIO.jl) that provides load/save functionalities for pfm files: this integration is done by the package [ImagePFM](https://github.com/Samuele-Colombo/ImagePFM.jl). If FileIO is already present (e.g. the original package), it will be overwritten by this custom version.

You can also create a new environment (_recommended_). First create a new folder and `cd` into this folder: this will become the home of the new environment. Then open the julia REPL and type the following commands:

```julia
import Pkg
Pkg.activate(".")
Pkg.add(url="https://github.com/Samuele-Colombo/FileIO.jl")
Pkg.add(url="https://github.com/Samuele-Colombo/ImagePFM.jl")
Pkg.add(url="https://github.com/Paolo97Gll/Raytracer.jl")
```

### [CLI tool](@id cli_tool_installation)

To use the CLI tool, you don't need to install the package or create a new environment: you just need to clone the repository:

```shell
git clone https://github.com/Paolo97Gll/Raytracer.jl.git
```

Then `cd` into the cloned folder, open the julia REPL, and type the following commands to instantiate the environment:

```julia
import Pkg
Pkg.activate(".")
Pkg.instantiate()
```
