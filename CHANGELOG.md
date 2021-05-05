# Changelog Raytracer.jl

## HEAD

### New features

- Add the implementation of an image tracer, needed to capture light from a scene ([#3](https://github.com/Paolo97Gll/Raytracer.jl/pull/3)).
- Add geometry implementation, needed to compute a 3D scene ([#2](https://github.com/Paolo97Gll/Raytracer.jl/pull/2)).

### Bug fixes

- Fix a bug where the method `fire_all_rays` returns an upside-down `HdrImage` ([#9](https://github.com/Paolo97Gll/Raytracer.jl/pull/9)).
- Fix a bug where the program segfault passing mixed types to `Vec` or `Normal` constructor ([#4](https://github.com/Paolo97Gll/Raytracer.jl/issues/4)).

## v0.1.0

- First release of the code
