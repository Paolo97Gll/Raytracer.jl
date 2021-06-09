# Raytracer.jl

Raytracing package for the generation of photorealistic images in Julia.

## Brief description

Coming soon!

## Overview

Coming soon!

## Installation

### Package

The package is still under development and is not available in the official registry. To add this package to your work environment, open julia REPL and type the following commands:

```julia
import Pkg
Pkg.add(url="https://github.com/Samuele-Colombo/FileIO.jl")
Pkg.add(url="https://github.com/Samuele-Colombo/ImagePFM.jl")
Pkg.add(url="https://github.com/Paolo97Gll/Raytracer.jl")
```

We use a [custom version of FileIO](https://github.com/Samuele-Colombo/FileIO.jl) that provides load/save functionalities for pfm files: this integration is done by the package [ImagePFM](https://github.com/Samuele-Colombo/ImagePFM.jl). If FileIO is already present (e.g. the original package), it will be overwritten by this custom version.

### CLI tool

To use it, clone this repository:

```shell
git clone https://github.com/Paolo97Gll/Raytracer.jl.git
cd Raytracer.jl
```

Then, open julia REPL and type the following commands to update your environment:

```julia
import Pkg
Pkg.activate(".")
Pkg.instantiate()
```
