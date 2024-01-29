# Core Image Filters

## Core Image API

```
// Ask the settings supported by a filter
let myFilter = CIFilter(name: "CIColorControls")
print(myFilter.inputKeys) // returns ["inputImage", "inputSaturation", "inputBrightness", "inputContrast"]
```

## Gaussian Blur

CIFilter(name: "CIGaussianBlur")

CIFilter(name: "CIGaussianBlur", parameters: [
    "inputRadius": 30
])

## Motion Blur

CIFilter(name: "CIMotionBlur")

CIFilter(name: "CIMotionBlur", parameters: [
    "inputRadius": 30,
    "inputAngle": 0
])

## Zoom Blur

CIFilter(name: "CIZoomBlur")

CIFilter(name: "CIZoomBlur", parameters: [
    "inputAmount": 40
])

## Dither

CIFilter(name: "CIDither")

CIFilter(name: "CIDither", parameters: [
    "inputIntensity": 0.6
])

## Color Clamp

CIFilter(name: "CIColorClamp")

CIFilter(name: "CIColorClamp", parameters: [
    "inputMinComponents": CIVector(x: 0, y: 0, z: 0, w: 0),
    "inputMaxComponents": CIVector(x: 1, y: 1, z: 1, w: 1)
])

## Colors Controls

Saturation: the larger the value, the more saturated the result. Default = 1
Brightness: the larger the value, the brighter the result. Default = 0
Contrast: the larger the value, the more contrast in the resulting image. Default = 1

CIFilter(name: "CIColorControls")

CIFilter(name: "CIColorControls", parameters: [
    "inputSaturation": 1,
    "inputBrightness": 0,
    "inputContrast": 1
])

## White Point Adjust

Color: A color to use as the white point. Default = CIColor(red: 1, green: 1, blue: 1, alpha: 1)

CIFilter(name: "CIWhitePointAdjust", parameters: [
    "inputColor": CIColor(red: 1, green: 1, blue: 1, alpha: 1)
])

## Color Invert

CIFilter(name: "CIColorInvert")

## Color Monochrome

Color: The monochrome color to apply to the image. Default = CIColor(red: 0.6, green: 0.45, blue: 0.3, alpha: 1)
Intensity: A value of 1.0 creates a monochrome image using the supplied color. A value of 0.0 has no effect on the image. Default = 1

CIFilter(name: "CIColorMonochrome", parameters: [
    "inputColor": CIColor(red: 0.6, green: 0.45, blue: 0.3, alpha: 1),
    "inputIntensity": 1
])

## XRay

CIFilter(name: "CIXRay")

## CMYK Halftone

Center: The x and y position to use as the center of the halftone pattern.
Width: The distance between dots in the pattern.
Angle: The angle of the pattern.
Sharpness: The sharpness of the pattern. The larger the value, the sharper the pattern.
GCR: The gray component replacement value. The value can vary from 0.0 to 1.0.
UCR: The under color removal value. The value can vary from 0.0 to 1.0.

CIFilter(name: "CICMYKHalftone")

CIFilter(name: "CICMYKHalftone", parameters: [
    "inputCenter": CIVector(x: 150, y: 150),
    "inputWidth": 6,
    "inputAngle": 0,
    "inputSharpness": 0.7,
    "inputGCR": 1,
    "inputUCR": 0.5
])

## Droste

CIFilter(name: "CIDroste", parameters: [
    "inputInsetPoint0": CIVector(x: 200, y: 200),
    "inputInsetPoint1": CIVector(x: 400, y: 400),
    "inputStrands": 1,
    "inputPeriodicity": 1,
    "inputRotation": 0,
    "inputZoom": 1
])

## Morphology Rectangle Minimum

CIFilter(name: "CIMorphologyRectangleMinimum", parameters: [
    "inputWidth": 100,
    "inputHeight": 0
])

## Morphology Rectangle Maximum

CIFilter(name: "CIMorphologyRectangleMaximum", parameters: [
    "inputWidth": 100,
    "inputHeight": 0
])

## Morphology Minimum

CIFilter(name: "CIMorphologyMinimum", parameters: [
    "inputRadius": 10
])

## Morphology Maximum

CIFilter(name: "CIMorphologyMaximum", parameters: [
    "inputRadius": 10
])

## Morphology Gradient

Shows the outline of an image

CIFilter(name: "CIMorphologyGradient", parameters: [
    "inputRadius": 1
])

## Hexagonal Pixellate

Scale: the size of the hexagons.

CIFilter(name: "CIHexagonalPixellate")

CIFilter(name: "CIHexagonalPixellate", parameters: [
    "inputCenter": CIVector(x: 150, y: 150),
    "inputScale": 8
])
