// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Swiper",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Swiper", targets: ["Swiper"]),
        .library(name: "SwiperCore", targets: ["SwiperCore"])
    ],
    targets: [
        .target(name: "SwiperCore"),
        .executableTarget(name: "Swiper", dependencies: ["SwiperCore"]),
        .testTarget(name: "SwiperCoreTests", dependencies: ["SwiperCore"])
    ],
    swiftLanguageModes: [.v5]
)
