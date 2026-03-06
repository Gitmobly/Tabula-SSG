# Retro: Rolling my Own GUI Library

Recently, I wrote a single-header library called [GGUI](https://git.deplet.ing/Jj/GGui) to create debug and prototype Graphical User Interfaces (GUIs) for applications on Windows & Mac.  
  
It was designed to be an immediate-mode, software-rasterized engine that can seamlessly process input, either via buttons or sliders. The platform layer passes in a pixel buffer to draw to, a UI state struct to track interaction, and an optional buffer for sound data (Pulse-Code Modulation or PCM samples) if the waveform visualization widget is being used. GGUI then handles drawing and layout, mutating the pixel buffer memory as requested. Widgets may also output interaction results or mutate bound values directly - for example, buttons will return `1` if clicked, or `0` if not. Sliders take the address of a variable, say a `float` for `volume`, and mutate the value directly, favoring directness and simplicity in-keeping with the immediate-mode philosophy.

Before we continue, here's a video of a 'breakout' clone written __entirely__ in GGUI sitting atop a Win32 platform layer.
