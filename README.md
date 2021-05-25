# Raytracer.jl

![julia-version][julia-version] ![status][status] ![package-version][package-version]

[julia-version]: https://img.shields.io/badge/julia_version-v1.6-9558B2?style=flat&logo=julia
[status]: https://img.shields.io/badge/project_status-🚧_work--in--progress-ba8a11?style=flat
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
  - [Command line tool](#command-line-tool)
    - [Installation](#installation-1)
    - [Usage](#usage-1)
      - [`raytracer_cli.jl`](#raytracer_clijl)
      - [`raytracer_cli.jl tonemapping`](#raytracer_clijl-tonemapping)
      - [`raytracer_cli.jl demo`](#raytracer_clijl-demo)
      - [`raytracer_cli.jl demo image`](#raytracer_clijl-demo-image)
      - [`raytracer_cli.jl demo animation`](#raytracer_clijl-demo-animation)
    - [Examples](#examples-1)
      - [Tone mapping](#tone-mapping)
      - [Demo](#demo)
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

## Command line tool

A command line tool `raytracer_cli.jl` is available to manage through this package the generation and rendering of photorealistic images.

### Installation

To use it, clone this repository:

```shell
git clone https://github.com/Paolo97Gll/Raytracer.jl.git
cd Raytracer.jl
```

Then, open julia and type the following commands to update your environment:

```julia
import Pkg
Pkg.activate(".")
Pkg.instantiate()
```

### Usage

#### `raytracer_cli.jl`

```text
usage: raytracer_cli.jl [-h] {tonemapping|demo}

Raytracing for the generation of photorealistic images in Julia.

commands:
  tonemapping  apply tone mapping to a pfm image and save it to file
  demo         show a demo of Raytracer.jl

optional arguments:
  -h, --help   show this help message and exit
```

#### `raytracer_cli.jl tonemapping`

```text
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

#### `raytracer_cli.jl demo`

```text
usage: raytracer_cli.jl demo [-h] {image|animation}

Show a demo of Raytracer.jl.

commands:
  image       render a demo image of Raytracer.jl
  animation   create a demo animation of Raytracer.jl (require ffmpeg)

optional arguments:
  -h, --help  show this help message and exit
```

#### `raytracer_cli.jl demo image`

```text
usage: raytracer_cli.jl demo image [-t CAMERA_TYPE]
                        [-p CAMERA_POSITION] [-o CAMERA_ORIENTATION]
                        [-d SCREEN_DISTANCE] [-r IMAGE_RESOLUTION]
                        [-R RENDERER] [-a ALPHA] [-g GAMMA]
                        [-O OUTPUT_FILE] [-h]

Render a demo image of Raytracer.jl.

optional arguments:
  -h, --help            show this help message and exit

generation:
  -t, --camera_type CAMERA_TYPE
                        choose camera type ('perspective' or
                        'orthogonal') (default: "perspective")
  -p, --camera_position CAMERA_POSITION
                        camera position in the scene as 'X,Y,Z'
                        (default: "-1,0,0")
  -o, --camera_orientation CAMERA_ORIENTATION
                        camera orientation as 'angX,angY,angZ'
                        (default: "0,0,0")
  -d, --screen_distance SCREEN_DISTANCE
                        only for 'perspective' camera: distance
                        between camera and screen (type: Float64,
                        default: 2.0)

rendering:
  -r, --image_resolution IMAGE_RESOLUTION
                        resolution of the rendered image (default:
                        "540:540")
  -R, --renderer RENDERER
                        type of renderer to use (`OnOff` or `Flat`)
                        (default: "OnOff")

tonemapping:
  -a, --alpha ALPHA     scaling factor for the normalization process
                        (type: Float64, default: 1.0)
  -g, --gamma GAMMA     gamma value for the tone mapping process
                        (type: Float64, default: 1.0)

files:
  -O, --output_file OUTPUT_FILE
                        output LDR file name (the HDR file will have
                        the same name, but with 'pfm' extension)
                        (default: "demo.jpg")
```

#### `raytracer_cli.jl demo animation`

```text
usage: raytracer_cli.jl demo animation [-t CAMERA_TYPE]
                        [-p CAMERA_POSITION] [-d SCREEN_DISTANCE]
                        [-r IMAGE_RESOLUTION] [-R RENDERER] [-a ALPHA]
                        [-g GAMMA] [-D DELTA_THETA] [-f FPS]
                        [-F OUTPUT_DIR] [-O OUTPUT_FILE] [-h]

Create a demo animation of Raytracer.jl, by generating n images with
different camera orientation and merging them into an mp4 video.
Require ffmpeg installed on local machine.

optional arguments:
  -h, --help            show this help message and exit

frame generation:
  -t, --camera_type CAMERA_TYPE
                        choose camera type ('perspective' or
                        'orthogonal') (default: "perspective")
  -p, --camera_position CAMERA_POSITION
                        camera position in the scene as 'X,Y,Z'
                        (default: "-1,0,0")
  -d, --screen_distance SCREEN_DISTANCE
                        only for 'perspective' camera: distance
                        between camera and screen (type: Float64,
                        default: 2.0)

frame rendering:
  -r, --image_resolution IMAGE_RESOLUTION
                        resolution of the rendered image (default:
                        "540:540")
  -R, --renderer RENDERER
                        type of renderer to use (`OnOff` or `Flat`)
                        (default: "OnOff")

frame tonemapping:
  -a, --alpha ALPHA     scaling factor for the normalization process
                        (type: Float64, default: 1.0)
  -g, --gamma GAMMA     gamma value for the tone mapping process
                        (type: Float64, default: 1.0)

animation parameter:
  -D, --delta_theta DELTA_THETA
                        Δθ in camera orientation (around z axis)
                        between each frame; the number of frames
                        generated is [360/Δθ] (type: Int64, default:
                        10)
  -f, --fps FPS         FPS (frame-per-second) of the output video
                        (type: Int64, default: 15)

files:
  -F, --output_dir OUTPUT_DIR
                        output directory (default: "demo_animation")
  -O, --output_file OUTPUT_FILE
                        name of output frames and animation without
                        extension (default: "demo")
```

### Examples

#### Tone mapping

You can use the `tonemapping` command to apply the tone mapping process to a pfm image. For example, you can use the following command to convert the image `test/memorial.pfm` into a jpg image:

```shell
julia raytracer_cli.jl tonemapping test/memorial.pfm memorial.jpg
```

You can also change the default values of `alpha` and/or `gamma` to obtain a better tone mapping, according to your source image:

```shell
julia raytracer_cli.jl tonemapping --alpha 0.35 --gamma 1.3 test/memorial.pfm memorial.jpg
```

#### Demo

You can use the `demo image` command to render a demo image:

```shell
julia raytracer_cli.jl demo image
```

It creates two files: `demo.pfm` (the HDR image) and `demo.jpg` (the LDR image). You can change the output file name, the LDR extension and other rendering parameters using the command options.

To create a demo animation, use the command `demo animation`:

```shell
julia raytracer_cli.jl demo animation
```

To enable multithreading, e.g. use 8 threads, use:

```shell
julia --threads 8 raytracer_cli.jl demo animation
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
