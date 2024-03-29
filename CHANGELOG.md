# Changelog Raytracer.jl

## v1.0.1

- Package dependencies updated.

- Add support for Julia 1.7.

## v1.0.0

First stable version.

### ⚠⚠⚠ BREAKING CHANGES ⚠⚠⚠

- CLI `demo` command is removed in favor of the command `render`: this command takes a SceneLang script (see below) as input and generates an hdr image (and optionally the corrispective ldr image).

### New package features

- Add SceneLang support ([#27](https://github.com/Paolo97Gll/Raytracer.jl/pull/27)).

### New CLI tool features

- Add `docs` command to show documentation informations.

- Add `--luminosity` option in `tonemapping` command ([#30](https://github.com/Paolo97Gll/Raytracer.jl/issues/30)).

### Improvements

- Improve documentation.

## v0.2.1

### New package features

- Add cubes, cylinders, and CSG ([#25](https://github.com/Paolo97Gll/Raytracer.jl/pull/25)).

### Improvements

- Improve documentation.

## v0.2.0

### ⚠⚠⚠ BREAKING CHANGES ⚠⚠⚠

- Removed type parameters from most structs. All floating points calculations are now performed on `Float32`. This provides a significant speedup. All code specifying type parameters will be broken from now on ([#23](https://github.com/Paolo97Gll/Raytracer.jl/pull/23)).

- Renamed the following functions:

  - `average_luminosity(image::HdrImage; δ::Float32)` -> `luminosity(image::HdrImage; δ::Float32)`

  - `normalize_image(image::HdrImage, α::Float32; luminosity::Float32)` -> `normalize(image::HdrImage, α::Float32; luminosity::Float32)`

  - `clamp_image(image::HdrImage)` -> `clamp(image::HdrImage)`

### New package features

- Add `PointLightRenderer` renderer with relative `PointLight` composite type and `Lights` alias ([#20](https://github.com/Paolo97Gll/Raytracer.jl/pull/20))

- Add `PathTracer` renderer ([#20](https://github.com/Paolo97Gll/Raytracer.jl/pull/20)).

- Add the implementation of an ortho-normal Basis (ONB) creation algorithm based on [Duff et al. 2017](https://graphics.pixar.com/library/OrthonormalB/paper.pdf) ([#20](https://github.com/Paolo97Gll/Raytracer.jl/pull/20)).

- Add a PCG-family Random Number Generator (RNG) based on [O'Neill 2014](https://www.cs.hmc.edu/tr/hmc-cs-2014-0905.pdf) as a `Random.AbstractRNG` ([#18](https://github.com/Paolo97Gll/Raytracer.jl/pull/18)).

- API now includes high-level functions for basic scene rendering, image tonemapping, and a `demo` function (see [user_utils.jl](https://github.com/Paolo97Gll/Raytracer.jl/blob/master/src/user_utils.jl)).

- Add `OnOffRenderer` and `FlatRenderer` renderers to apply to the scene ([#17](https://github.com/Paolo97Gll/Raytracer.jl/pull/17)).

- Add the implementation of materials for our shapes, describing both the BRDF and radiance of the shape interface ([#17](https://github.com/Paolo97Gll/Raytracer.jl/pull/17)).

- Add the implementation of some basic shapes, such as spheres ([#11](https://github.com/Paolo97Gll/Raytracer.jl/pull/11)).

- Add the implementation of an image tracer, needed to capture light from a scene ([#3](https://github.com/Paolo97Gll/Raytracer.jl/pull/3)).

- Add geometry implementation, needed to compute a 3D scene ([#2](https://github.com/Paolo97Gll/Raytracer.jl/pull/2)).

### New CLI tool features

- Add `demo` command to show a demo rendering ([#13](https://github.com/Paolo97Gll/Raytracer.jl/pull/13)).

## v0.1.0

- First release of the code
