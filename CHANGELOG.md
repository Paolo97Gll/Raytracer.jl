# Changelog Raytracer.jl

## HEAD

### New package features

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
