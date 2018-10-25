# portar

### (aka WhereARMyKeys)

Take a picture as your anchor and then use it to anchor AR content to **achieve
persistence without the need of external libraries.**

![Demo_1](./demo/spesar_demo_gif_10-40seconds.gif)
![Demo_2](./demo/spesar_demo_gif_40-full_seconds.gif)

It uses ARKit Anchor Images to achieve persistence.

## Getting started

### Prerequisites

* XCode Version >= 9.3 (9E145)
* iOS device which can run ARKit
* iOS device with iOS >= 11.3

### Setup

1. Clone
2. `cd` into the project's dir
3. Run `pod install`
4. Open the workspace

### App usage

1. Start it
2. Take a picture so that it can become your anchoring point
3. Show the anchor to the application again
4. Place content with respect to the anchor
5. Close the app
6. Open it again
7. Point at your anchor

Content now appears where you had left it.

### Contributing and disclaimer

This repo is release as-is and purely for educational purposes. The code is
old but can be used as inspiration. If you encounter issues, do feel free to
fork + open pull requests and I'll integrate the fixes.

## Demo video

[Demo video here](https://twitter.com/albtaiuti/status/988504988728135680)

## Author

[Alberto Taiuti](https://twitter.com/albtaiuti)

## License

Please see [LICENSE](./LICENSE)
