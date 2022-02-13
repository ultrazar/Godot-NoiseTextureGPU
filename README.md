# Godot-NoiseTextureGPU
Godot OpenSimplexNoise using a shader

![Noise](https://user-images.githubusercontent.com/48863881/125081487-58080880-e0c6-11eb-83c7-6495a36eabf7.PNG)

![Shader](https://user-images.githubusercontent.com/48863881/125363432-e43d5880-e370-11eb-884c-6d797ba2bdb6.PNG)

Adapted from: https://github.com/ashima/webgl-noise

SimplexNoise (currently 2D, TODO 3D and 4D) programmed in Shader, GDScript and C++ (GDNative)

How to use (for GPU):
 1. Create a Sprite/TextRect
 2. In texture parameter, select NoiseTexture_v2
 3. Press render button

elif (for CPU):
 - Need to compile the GDNative version for your system (you can use this tutorial: https://gist.github.com/willnationsdev/437eeaeea2e675c0bea53343f7ecd4cf) or change some lines for using GDScript version (alert, very slow). I only included the binary compiled that works for my machine. I'm new to GDNative and some help would be fully appreciated!

