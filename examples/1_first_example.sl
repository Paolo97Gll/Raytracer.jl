# Here is a comment

# The language is key-sensitive:
# - Command keywords are uppercase
# - Types have the first letter uppercase
# - Identifiers (i.e. variable names) must be lowercase

# Each expression must begin with a command keyword


##############
# SET command


# SET: define a variable

# Here we define a variable of type `Float`, name `clock` and value `150`
SET clock 150

# Change a variable will throw an error
# SET clock ...

# Colors are defined with angular brackets
SET black <0, 0, 0>

# You can use variables into definitions
SET sky_material Material(Diffuse(Uniform(black)), Uniform(<0.7, 0.5, 1>))

# You can go on new line or indent as you wish
SET ground_material
    Material(
        Diffuse(
            Checkered(
                <0.3, 0.5, 0.1>,
                <0.1, 0.2, 0.5>,
                4
            )
        ),
        Uniform(
            <0, 0, 0>
        )
    )

SET sphere_material Material(Specular(Uniform(<0.5, 0.5, 0.5>)),
                             Uniform(<0, 0, 0>))


##############
# ADD command


# ADD: add a shape or a light to the scene

# You can define a shape and then add it to the world with the command ADD
SET sky_plane Plane(sky_material, Translation([0, 0, 100]) * Rotation_Y(clock))
ADD sky_plane

# Or add it directly
ADD Plane(ground_material, Identity())
ADD Sphere(sphere_material, Translation([0, 0, 1]))


################
# USING command


# USING: setup camera, renderer and image

USING Camera(Perspective(), Rotation_z(30) * Translation([-4, 0, 1]), 1, 1)
# Using another camera will throw an error
# USING Camera(Perspective(), Rotation_z(50) * Translation([-4, 0, 1]), 2, 1)

USING Renderer(Flat())
# Using another renderer will throw an error

USING Image(1920, 1080)
# Using another image will throw an error
