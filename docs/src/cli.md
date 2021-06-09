# Command line interface (CLI) tool

A command line tool `raytracer_cli.jl` is available to manage through this package the generation and rendering of photorealistic images.

This CLI tool recalls functions already present in the `Raytracer.jl` module, so is possible to run these commands also from the REPL.

## Installation

To use it, clone this repository:

```shell
git clone https://github.com/Paolo97Gll/Raytracer.jl.git
cd Raytracer.jl
```

Then, open julia REPL and type the following commands to update your environment:

```@repl
import Pkg
Pkg.activate(".")
Pkg.instantiate()
```

## Usage

The menu tree is:

```text
raytracer_cli.jl
├── tonemapping
└── demo
    ├── image
    └── animation
```

### `raytracer_cli.jl`

```text
usage: raytracer_cli.jl [--version] [-h] {tonemapping|demo}

Raytracing for the generation of photorealistic images in Julia.

commands:
  tonemapping  apply tone mapping to a pfm image and save it to file
  demo         show a demo of Raytracer.jl

optional arguments:
  --version    show version information and exit
  -h, --help   show this help message and exit
```

### `raytracer_cli.jl tonemapping`

We support as output image type all the formats supported by the packages [ImageIO](https://github.com/JuliaIO/ImageIO.jl), [ImageMagick](https://github.com/JuliaIO/ImageMagick.jl) and [QuartzImageIO](https://github.com/JuliaIO/QuartzImageIO.jl), including: jpg, png, tiff, ppm, bmp, gif, ...

```text
usage: raytracer_cli.jl tonemapping [-a ALPHA] [-g GAMMA] [--version]
                        [-h] input_file output_file

Apply tone mapping to a pfm image and save it to file.

optional arguments:
  --version          show version information and exit
  -h, --help         show this help message and exit

tonemapping settings:
  -a, --alpha ALPHA  scaling factor for the normalization process
                     (type: Float32, default: 0.5)
  -g, --gamma GAMMA  gamma value for the tone mapping process (type:
                     Float32, default: 1.0)

files:
  input_file         path to input file, it must be a PFM file
  output_file        output file name
```

### `raytracer_cli.jl demo`

```text
usage: raytracer_cli.jl demo [--version] [-h] {image|animation}

Show a demo of Raytracer.jl.

commands:
  image       render a demo image of Raytracer.jl
  animation   create a demo animation of Raytracer.jl (require ffmpeg)

optional arguments:
  --version   show version information and exit
  -h, --help  show this help message and exit
```

### `raytracer_cli.jl demo image`

```text
usage: raytracer_cli.jl demo image [--force] [-t CAMERA_TYPE]
                        [-p CAMERA_POSITION] [-o CAMERA_ORIENTATION]
                        [-d SCREEN_DISTANCE] [-r IMAGE_RESOLUTION]
                        [-R RENDERER] [-A ANTIALIASING] [--pt_n PT_N]
                        [--pt_max_depth PT_MAX_DEPTH]
                        [--pt_roulette_depth PT_ROULETTE_DEPTH]
                        [-a ALPHA] [-g GAMMA] [-O OUTPUT_FILE]
                        [--version] [-h]

Render a demo image of Raytracer.jl.

optional arguments:
  --force               force overwrite
  --version             show version information and exit
  -h, --help            show this help message and exit

camera:
  -t, --camera_type CAMERA_TYPE
                        choose camera type ("perspective" or
                        "orthogonal") (default: "perspective")
  -p, --camera_position CAMERA_POSITION
                        camera position in the scene as "X,Y,Z"
                        (default: "-3,0,0")
  -o, --camera_orientation CAMERA_ORIENTATION
                        camera orientation as "angX,angY,angZ"
                        (default: "0,0,0")
  -d, --screen_distance SCREEN_DISTANCE
                        only for "perspective" camera: distance
                        between camera and screen (type: Float32,
                        default: 2.0)

rendering:
  -r, --image_resolution IMAGE_RESOLUTION
                        resolution of the rendered image (default:
                        "540:540")
  -R, --renderer RENDERER
                        type of renderer to use ("onoff", "flat",
                        "path" or "pointlight") (default: "path")
  -A, --antialiasing ANTIALIASING
                        number of samples per pixel (must be a perfect
                        square) (type: Int64, default: 0)

path-tracer options (only for "path" renderer):
  --pt_n PT_N           number of rays fired for mc integration (type:
                        Int64, default: 10)
  --pt_max_depth PT_MAX_DEPTH
                        maximum number of reflections for each ray
                        (type: Int64, default: 2)
  --pt_roulette_depth PT_ROULETTE_DEPTH
                        depth of the russian-roulette algorithm (type:
                        Int64, default: 3)

tonemapping:
  -a, --alpha ALPHA     scaling factor for the normalization process
                        (type: Float32, default: 0.75)
  -g, --gamma GAMMA     gamma value for the tone mapping process
                        (type: Float32, default: 1.0)

files:
  -O, --output_file OUTPUT_FILE
                        output LDR file name (the HDR file will have
                        the same name, but with "pfm" extension)
                        (default: "demo.jpg")
```

### `raytracer_cli.jl demo animation`

```text
usage: raytracer_cli.jl demo animation [--force] [-t CAMERA_TYPE]
                        [-p CAMERA_POSITION] [-d SCREEN_DISTANCE]
                        [-r IMAGE_RESOLUTION] [-R RENDERER]
                        [-A ANTIALIASING] [--pt_n PT_N]
                        [--pt_max_depth PT_MAX_DEPTH]
                        [--pt_roulette_depth PT_ROULETTE_DEPTH]
                        [-a ALPHA] [-g GAMMA] [-D DELTA_THETA]
                        [-f FPS] [-F OUTPUT_DIR] [-O OUTPUT_FILE]
                        [--version] [-h]

Create a demo animation of Raytracer.jl, by generating n images with
different camera orientation and merging them into an mp4 video.
Require ffmpeg installed on local machine.

optional arguments:
  --force               force overwrite
  --version             show version information and exit
  -h, --help            show this help message and exit

frame camera:
  -t, --camera_type CAMERA_TYPE
                        choose camera type ("perspective" or
                        "orthogonal") (default: "perspective")
  -p, --camera_position CAMERA_POSITION
                        camera position in the scene as "X,Y,Z"
                        (default: "-3,0,0")
  -d, --screen_distance SCREEN_DISTANCE
                        only for "perspective" camera: distance
                        between camera and screen (type: Float32,
                        default: 2.0)

frame rendering:
  -r, --image_resolution IMAGE_RESOLUTION
                        resolution of the rendered image (default:
                        "540:540")
  -R, --renderer RENDERER
                        type of renderer to use ("onoff", "flat",
                        "path" or "pointlight") (default: "path")
  -A, --antialiasing ANTIALIASING
                        number of samples per pixel (must be a perfect
                        square) (type: Int64, default: 0)

path-tracer options (only for "path" renderer):
  --pt_n PT_N           number of rays fired for mc integration (type:
                        Int64, default: 10)
  --pt_max_depth PT_MAX_DEPTH
                        maximum number of reflections for each ray
                        (type: Int64, default: 2)
  --pt_roulette_depth PT_ROULETTE_DEPTH
                        depth of the russian-roulette algorithm (type:
                        Int64, default: 3)

frame tonemapping:
  -a, --alpha ALPHA     scaling factor for the normalization process
                        (type: Float32, default: 0.75)
  -g, --gamma GAMMA     gamma value for the tone mapping process
                        (type: Float32, default: 1.0)

animation parameter:
  -D, --delta_theta DELTA_THETA
                        Δθ in camera orientation (around z axis)
                        between each frame; the number of frames
                        generated is [360/Δθ] (type: Float32, default:
                        10.0)
  -f, --fps FPS         FPS (frame-per-second) of the output video
                        (type: Int64, default: 15)

files:
  -F, --output_dir OUTPUT_DIR
                        output directory (default: "demo_animation")
  -O, --output_file OUTPUT_FILE
                        name of output frames and animation without
                        extension (default: "demo")
```

## Examples

### Tone mapping

You can use the `tonemapping` command to apply the tone mapping process to a pfm image. For example, you can use the following command to convert the image `test/memorial.pfm` into a jpg image:

```shell
julia raytracer_cli.jl tonemapping test/memorial.pfm memorial.jpg
```

You can also change the default values of `alpha` and/or `gamma` to obtain a better tone mapping, according to your source image:

```shell
julia raytracer_cli.jl tonemapping --alpha 0.35 --gamma 1.3 test/memorial.pfm memorial.jpg
```

### Demo

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