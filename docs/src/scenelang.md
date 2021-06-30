# [SceneLang](@id scenelang)

## Contents

```@contents
Pages = ["scenelang.md"]
Depth = 5
```

## Description

SceneLang is a Domain-Specific Language (DSL) used to describe a 3D scene that can be rendered by Raytracer.

Being a DSL, SceneLang lacks some of the basic features of general purpose languages: there are no functions or custom types or even flexible arithmetic operations. SceneLang is made only to construct scenes to be rendered.

To render the content of a scenelang script just invoke the cli tool command:

```shell
julia raytracer_cli.jl render myscript.sl
```

where `.sl` is the suffix for a SceneLang script.

Each SceneLang script is parsed through the interpreter present in module `Raytracer.Interpreter`, which interprets the script by first interpreting the stream of charachters associated with the script as a list of token and then evaluating how these tokens relate to each other as a syntax.

Let's start by looking at what tokens are in a SceneLang script.

## [Script tokenization](@id scenelang_script_tokenization)

In a SceneLang script there are mainly five classes of tokens:

1. [Commands](@ref scenelang_token_commands)
2. [Types](@ref scenelang_token_types)
3. [Keywords](@ref scenelang_token_keywords)
4. [Identifiers](@ref scenelang_token_identifiers)
5. [Literals](@ref scenelang_token_literals)

### [Commands](@id scenelang_token_commands)

Commands are all-uppercase words. Their role is to indicate that an action will be performed on arguments that follow.

!!! warning
    Commands are a finite group of predetermined words, therefore the lexer throws an exception when it finds an all-uppercase word that is not a listed command.

###### Examples

```text
SET  # valid command token
DROP # invalid command token, not in list
Set  # not a command token, lowercase letters are present in the word
```

### [Types](@id scenelang_token_types)

Types are words starting with an uppercase letter and at least one lowercase letter in the rest of the word. Their role is to specify the type of a value when it is constructed.

!!! warning
    Types, as commands, are a finite group of predetermined words, therefore the lexer throws an exception when it finds an uppercase-starting word that is not a listed type.

###### Examples

```text
Pigment  # valid type token
PIgment  # invalid type token, not in list
pigment  # not a type token, first letter not uppercase
```

### [Keywords](@id scenelang_token_keywords)

Keywords are words preceded by a dot (`.`) marker. They are used either as a specifier to a type or command or as an attribute name when constructing a value.

!!! warning
    Keywords are not a global scope defined list of names, but they have meaning only in certain semantic contexts, but the lexer is unaware of this so any word following a dot will be marked as a keyword even if it is syntactically invalid.

###### Examples

```text
.Uniform         # valid keyword token
.transformation  # valid keyword token, there is no rule on capitalization
transformation   # not a keyword token, word not preceded by a dot
```

### [Identifiers](@id scenelang_token_identifiers)

Identifiers are words, starting with a lowercase letter, that are intended to be paired with an instance of a type and can be used in place of that value.

###### Examples

```text
identifier        # valid identifier token
_IDENTIFIER       # valid identifier token, no capitalization rule after the first letter
a_long_identifier # valid identifier token in snake case
Not_an_identifier # not an identifier, first letter must be lowercase or an underscore
```

!!! tip
    For ease of visual parsability we suggest to avoid the second style above and to prefer [snake case](https://en.wikipedia.org/wiki/Snake_case) for long identifiers and keep everything lowercase.

### [Literals](@id scenelang_token_literals)

Literals are every other token in the script: numbers, strings, and mathematical expressions.

```julia
6                      # this is a LiteralNumber token
"this is a string"     # this is a LiteralString token
$ 1 + 2id ^ 4 - 1e-2 $ # this is a MathExpression token
```

`MathExpression` tokens are a peculiar feature of SceneLang and will be explored deeper [in its own chapter](@ref scenelang_syntax_structure_constructors_math_expressions).

## [Syntax structure](@id scenelang_syntax_structure)

The syntax of SceneLang is composed of only three entities:

1. [Variables](@ref scenelang_syntax_structure_variables)
2. [Constructors](@ref scenelang_syntax_structure_constructors)
3. [Instructions](@ref scenelang_syntax_structure_instructions)

### [Variables](@id scenelang_syntax_structure_variables)

Variables in SceneLang are composed only of an identifier token, so the two terms could be used interchangeably, since the difference stands only in the fact that "variables" is their name when analyzing the syntax while "identifiers" is when talking about lexicon.

The value stored into a variable cannot be altered or copied into other variables. Values only serve to label a particular instance of an object construted at variable set-up and stored in a dictionary. They behave exactly as if that object were contructed in-place. The only places where a varible is explicitly requested to be is when they are set up and when they are destroyed. In all other instances they could be as substituted with appropriate constructors, at the cost of readability and time to parse the script.

### [Constructors](@id scenelang_syntax_structure_constructors)

Constructors are a syntactical construct that constructs an object into memory.

There are three types of constructors **symbolical constructors**, **named constructors**, and **command constructors**.

Symbolical constructors determine the output type by the symbols present around the arguments, while named constructors have the arguments surrounded by parenthesis an preceded by the type name (and sometimes a type specificator keyword).

```julia
<1, 0, 0>      # a symbolic constructor for a color
Color(1, 0, 0) # the same color but in a named constructor form
```

Named constructors have an additional characteristic: they can have default values and can take keyword arguments:

```julia
Color(1)       # the same color as in the previous example but the second
               # and third arguments are defaulted to 0
Color(.R 1)    # as above but with a keyword argument
```

!!! tip
    Keyword arguments may seem verbose at first but come in very handy both when trying to understand what the code is doing and when one wants to list arguments in a different order than standard.

!!! warning
    Mixed positional and keyword argument types are allowed as long as the positional arguments precede the keyword ones and as long as the keyword arguments do not redefine positional arguments:

    ```julia
    Color(1, .B 0.5, .G 0.75) # valid mixed argument constructor
    Color(.R 1, 0.75, 0.5)    # throws InvalidKeyword exception: positional after keyword
    Color(1, .R 0.5)          # throws InvalidKeyword exception: keyword tries to redefine
                              # the first positional argument
    ```

Command constructors exist either to make the code more readable and/or to simplify notation. They are composed of a command and one or more arguments. If more than one argument may be required these must be surrounded by curved parenthesis. A clear example are the commands to create rotation matrices without requiring the user to manually type the transformation matrix.

For example the following two constructors return the same transformation:

```julia
Transformation([1.0,  0.0,        0.0,       0.0,
                0.0,  0.707107,  -0.707107,  0.0,
                0.0,  0.707107,   0.707107,  0.0,
                0.0,  0.0,        0.0,       1.0])
ROTATE(.X 45)
```

Numbers and strings can be considered primitive types and thus require a dedicated tokenization. Therefore a named or command constructor for them would be needlessy redundant and verbose as their constructor would take only one argument of the same type of the one produced and there is no risk of ambiguity.

###### Examples

```julia
9          # since a number is a primitive type it can be
           # constructed by simply typing the number itself
"a string" # a string must surround the desired text with double quotes
```

Now we'll list all constructors for all the different types supported by SceneLang.

#### [Numbers](@id scenelang_syntax_structure_constructors_numbers)

As stated above, numbers are primitive types and have a symbolic constructor which is a simple numeric token.

This constructor supports integer notation `1`, dotted notations `1.0` and `1.`, and the scientific notations `1e2`, `1e+2`, `1e-2` and equivalent notation using `E`.

!!! warning
    The notation `.1` is not supported, the parser would interpret it as a keyword, use `+.1`, `-.1`, or `0.1` instead.

#### [Strings](@id scenelang_syntax_structure_constructors_strings)

Being a primitive type, strings only have a symbolic constructor.

Strings are surrounded by double quotes (`"`) and support the usual set of escaped characters (e.g. `\n`, `\t`, ...). SceneLang strings do not support formatting or interpolations.

#### [Colors](@id scenelang_syntax_structure_constructors_colors)

Colors have a named constructor with signature

```julia
Color(.R red::number = 0, .G green::number = 0, .B blue::number = 0)
```

and a symbolic constructor with signature

```julia
<red::number, green::number, blue::number>
```

Note that these colors are pixels of an HDR image, therefore have no upper bound.

#### [Points](@id scenelang_syntax_structure_constructors_points)

Points have a named constructor with signature

```julia
Point(.X x::number = 0, .Y y::number = 0, .Z z::number = 0)
```

and a symbolic constructor with signature

```julia
{x::number, y::number, z::number}
```

#### [Lists](@id scenelang_syntax_structure_constructors_lists)

Lists have a named constructor with signature

```julia
List(element::number, ::number...)
```

and a symbolic constructor with signature

```julia
[element::number, ::number...]
```

#### [Transformations](@id scenelang_syntax_structure_constructors_transformations)

Transformations have a named constructor with signature

```julia
Transformation(matrix::list.lenght16)
```

Transformations can be concatenated using the symbol `*` which behaves like a matrix multiplication operation.

and four command constructors.

##### `SCALE` command

The `SCALE` command constructs a scaling transformation and has two different signatures:

```julia
SCALE(.X x::number = 1, .Y y::number = 1, .Z z::number = 1) # scales by different factors on the given axes
SCALE factor::number # scales uniformly on all axes
```

##### `TRANSLATE` command

The `TRANSLATE` command constructs a translation transformation. It has the signature

```julia
TRANSLATE(.X x::number = 0, .Y y::number = 0, .Z z::number = 0)
```

##### `ROTATE` command

The `ROTATE` command constructs a rotation transformation combining rotations in different axis. In the scene's euclidean 3D space scaling and translation transformations are commutable along different axes, so the order of application of the transformation does not matter: this is not the case for rotations.

Therefore the `ROTATE` command has a peculiar syntax for its arguments: after the command a series of keywords indicating the rotation axis are followed by the rotation angles in degrees in a way similar to the following example.

```julia
ROTATE(.X 45 * .Z 30 * .X 20 * .Y 15)
```

You can clearly see that in this syntax keywords can be repeated and are, therefore, non-optional. Furthermore, the order in which they are written matters as the result of the construction will be the concatenation of all the individual rotations. This is the reason why the arguments are not separated by commas but by concatenation symbols `*`.

#### [Images](@id scenelang_syntax_structure_constructors_images)

Images have two name constructors with signature

```julia
Image(file_path::string) # loads an image from a file at the given path if the format is valid
Image(width::number.integer, height::number.integer) # constructs a black image of size `width`x`height`
```

and a command constructor with signature

```julia
LOAD file_path::string # loads an image from a file at the given path if the format is valid
```

#### [Pigments](@id scenelang_syntax_structure_constructors_pigments)

Pigments have named constructors associated with each of their subtype specifiers. Their signatures are:

```julia
Pigment.Uniform(.color color::color = <1, 1, 1>)
Pigment.Checkered(.N::number.integer = 2 , .color_on color_on::color = <1, 1, 1>, .color_off::color = <0, 0, 0>)
Pigment.Image(.image image::image = Image(1, 1))
```

#### [BRDFs](@id scenelang_syntax_structure_constructors_brdfs)

BRDFs have named constructors associated with each of their subtype specifiers. Their signatures are:

```julia
Brdf.Diffuse(.pigment pigment::pigment = Pigment.Uniform())
Brdf.Specular(.pigment pigment::pigment = Pigment.uniform(), .threshold_angle_rad angle::number = 0.0017453294)
```

#### [Materials](@id scenelang_syntax_structure_constructors_materials)

Materials have a named constructor with signature

```julia
Material(.brdf brdf::brdf = Brdf.Diffuse(), .emitted_radiance radiance::pigment = Pigment.Uniform())
```

#### [Shapes](@id scenelang_syntax_structure_constructors_shapes)

Shapes have named constructors associated with each of their subtype specifiers. Their signatures are:

```julia
Shapes.Sphere  (.material material::material = Material(),
                .transformation transformation::transformation = SCALE())
Shapes.Plane   (.material material::material = Material(),
                .transformation transformation::transformation = SCALE())
Shapes.Cube    (.material material::material = Material(),
                .transformation transformation::transformation = SCALE())
Shapes.Cylinder(.material material::material = Material(),
                .transformation transformation::transformation = SCALE())
```

Furthermore, shapes have also command constructors for Constructive Solid Geometries (CSG). Their signatures are:

```julia
UNITE(shape::shape, ::shape...)
INTERSECT(shape::shape, ::shape...)
DIFF(shape::shape, ::shape...)
FUSE(shape::shape, ::shape...)
```

#### [Lights](@id scenelang_syntax_structure_constructors_lights)

Lights have a named constructor with signature

```julia
Light(.position position::point = {0,0,0},
      .color color::color = <1,1,1>,
      .linear_radius radius::number = 0)
```

#### [PCGs](@id scenelang_syntax_structure_constructors_pcgs)

PCGs have a named constructor with signature

```julia
Pcg(.state state::number.integer = 42,
    .inc   inc::number.integer = 54)
```

#### [Renderers](@id scenelang_syntax_structure_constructors_renderers)

Renderers have named constructors associated with each of their subtype specifiers. Their signatures are:

```julia
Renderer.OnOff(.on_color on::color = <1,1,1>,
               .off_color off::color = <0,0,0>)
Renderer.Flat(.background_color background::color = <0,0,0>)
Renderer.PointLight(.background_color background::color = <0,0,0>,
                    .ambient_color ambient::color = <1e-3,1e-3,1e-3>)
Renderer.PathTracer(.background_color color::color = <0,0,0>,
                    .rng              rng::pcg = Pcg()
                    .n                n::number.integer = 10,
                    .max_depth        max::number.integer = 2,
                    .roulette_depth   roulette::number.integer = 3)
```

#### [Tracers](@id scenelang_syntax_structure_constructors_tracers)

Tracers have a named constructor with signature

```julia
Tracer(.samples_per_side samples::number = 1, .rng rng::pcg = Pcg())
```

#### [MathExpressions](@id scenelang_syntax_structure_constructors_math_expressions)

Numbers, points, and colors can also be constructed via a `MathExpression` token. Math expressions are sections of code surrounded by dollar signs `$`. They can contain only mathematical operations, numbers and identifiers storing numbers.

These expressions are first checked for validity at lexing time, where it is ensured that they only contain numbers, identifiers, and valid operations and that these operations have the right amount of arguments to them. The valid operations are:

op symbol | # of args| action
----------|---------:|----------
\+        |1+        | add
\-        | 2        | subtract
\*        | 1+       | multiply
/         | 2        | float divide
div       | 2        | integer divide
%         | 2        | modulo
^         | 2        | raise to the power of
floor     | 1        | approximate to integer by defect
ceil      | 1        | approximate to integer by excess
round     | 1        | approximate to nearest integer
exp       | 1        | natural base exponential
exp2      | 1        | binary base exponential
exp10     | 1        | decimal base exponential
log       | 1        | natural base logarithm
log2      | 1        | binary base logarithm
log10     | 1        | decimal base logarithm
log1p     | 1        | natural base logarithm of `arg + 1`
sin       | 1        | sine function (argument in radians)
cos       | 1        | cos function (argument in radians)
tan       | 1        | tan function (argument in radians)
asin      | 1        | arcsine function
acos      | 1        | arccos function
atan      | 1 or 2   | arctan function
Point     | 3        | Julia `Point` constructor
RGB       | 3        | Julia `RGB` constructor

After successful tokenization the expression is evaluated. Starting with the innermost expression all the identifiers are substituted with their value (if they are defined and contain a number, otherwise an exception will be thrown) an then the result of the expression is calculated. If the result is a finite number the second innermost expression is evaluated and so on until the outermost expression is evaluated. If the result is either infinite or `NaN` an exception will be thrown.

The tokenization and evaluation processes make use of the `Meta.parse` and `eval` functions provided by the Julia language. Therefore every valid Julia syntax for mathematical expressions is considered valid as long as it respects the restrictions discussed previously in this section.

###### Examples

```julia
SET a 9                   # set the `a` variable to be equal to 9
SET res1 $1 + 2a$         # this will set `res1` to be equal to 19
# SET res2 $1 + 2b$       # this would throw an `UndefinedIdentifier` exception
# SET res3 $div(1, 2, 3)$ # this would throw an `InvalidExpression` exception
```

### [Instructions](@id scenelang_syntax_structure_instructions)

SceneLang scripts are a series of instructions parsed by the interpreter.

Each instruction starts with an instruction command and ends when all the possible arguments are consumed.

Arguments can only be variables or constructors.

!!! info
    In the following command signatures we will use:
    - enclosing angular brackets`<>` to isolate single variable elements of the signature;
    - a pipe `|` between two elements indicates that one or the other can be present at that position;
    - enclosing squared brackets `[]` to indicate optional arguments;
    - appended dots `...` to indicate that the previous element may be repeated an indefinite amount of times.

#### `SET`

Assign to a variable a constructed variable.

```julia
SET <<identifier> <constructor>>...
```

!!! note
    All variables are constants in Scenelang and they exist and can't be overwritten until they are `UNSET`.

!!! note
    You cannot set an identifier to be equal to the value stored in another identifier as it is not needed in a program where the lifetime of the value is the lifetime of the variable.

###### Examples

```julia
SET my_number 6 # sets `my_number` to be equal to 6

# <identifier> <value> pairs can be chained after a SET statement
SET
    sphere Shape.Sphere()
    cube   Shape.Cube()
# as soon as the next token in the series is
# not an identifier the SET statement is interrupted
```

!!! tip
    Since SceneLang is not sensitive to spaces and newlines chained commands can have any layout you prefer, we still suggest, for easier visual parsing, the style we use in our examples of separating every element by a newline and a tabulation.

#### `UNSET`

Destroy a variable and the assigned value.

```julia
UNSET <identifier>...
```

###### Examples

```julia
UNSET my_number # my_number is now not assigned to any value and
                # cannot be called any more unless it is SET again

# <identifier>s can be chained after an UNSET statement
UNSET
    sphere
    cube
# as soon as the next token in the series is
# not an identifier the UNSET statement is interrupted
```

#### `SPAWN`

Spawns a shape or a light into the rendered world.

```julia
SPAWN <<shape_identifier>|<shape_constructor>>...
```

###### Examples

```julia
SET my_number 10
SET my_sphere Shape.Sphere()

# <identifier>s or <constructor>s can be chained after a SPAWN statement
SPAWN
    my_sphere    # my sphere is spawned into the world
#   my_number    # this would throw a `WrongValueType` exception
    Shape.Cube() # spawned shapes can also be constructed in-place
    Light()      # lights can also be spawned
# as soon as the next token in the series is
# not an identifier the SPAWN statement is interrupted
```

#### `USING`

Sets a rendering settings to a given value.

```julia
USING <<camera_identifier>  |<camera_constructor>  |
       <image_identifier>   |<image_constructor>   |
       <renderer_identifier>|<renderer_constructor>|
       <tracer_identifier>  |<tracer_constructor>
      >...
```

The rendering settings that can be set are:

- the camera to be used and its properties;
- the image to be impressed;
- the renderer to be used and its properties;
- the tracer to be used and its properties.

!!! warning
    `USING` instruction must be used **once and only once per setting** within a script. if a setting is not defined an `UndefinedSetting` exception will be thrown, else, if a definition occurs more than once, a `SettingRedefinition` exception will be thrown.

###### Examples

```julia
USING Camera.Orthogonal() # sets the camera setting to
                          # be the default orthogonal camera

SET p_camera Camera.Perspective()
SET image Image(1920, 1080)

# <identifier>s or <constructor>s can be chained after a USING statement
USING
    Renderer.PointLight() # Usable objects can
    Tracer()              # be constructed in-place
    image                 # or they could be used by identifier
#   p_camera			  # this would throw a `SettingRedefinition` exception
# as soon as the next token in the series is
# not an identifier the USING statement is interrupted
```

#### `DUMP`

Prints to `stdout` the specified content. Used mainy as a debug tool.

```julia
# prints the value associated with the specified field of the scene
DUMP.variables
DUMP.world
DUMP.lights
DUMP.image
DUMP.camera
DUMP.renderer
DUMP.tracer

DUMP.ALL # prints all of the above
```
