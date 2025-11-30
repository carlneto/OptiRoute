# 🗺️ OptiRoute

[![Swift Version](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17%2B-blue.svg?style=flat)](https://developer.apple.com/ios/)
[![macOS](https://img.shields.io/badge/macOS-13%2B-lightgrey.svg?style=flat)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat)](LICENSE)

---

## 🚀 Project Overview

**OptiRoute** is a Swift library and utility for **route processing and optimization** with geolocation data. It provides tools for:

- Cleaning and preparing GPS tracks (removing outliers and proximity-based duplicates)
- Calculating distances, estimated travel times, and statistics
- Performing geometric operations on coordinates (bearing, interpolation, centroids, midpoints, clustering)
- Integration with **MapKit**: polylines, annotations, snapshots, nearby point searches along a route
- Reverse geocoding for locality names and timezone identification

OptiRoute is ideal for travel apps, fitness tracking, mapping tools, and route analytics.

---

## 🛠️ Requirements

- **Operating Systems:**
  - iOS 17+
  - macOS 13 (Ventura)+
- **Xcode:** 16+
- **Swift:** 6.0+
- **Frameworks:** MapKit, CoreLocation (HealthKit optional)

> ⚠️ Some features rely on recent MapKit APIs. Adjust the minimum deployment target if using older functionality.

---

## ⚡ Installation

### Swift Package Manager (SPM) – Recommended

1. In Xcode: `File → Add Packages…` → Enter the repository URL and choose a version.
2. Or add manually to your `Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
        .iOS(.v17), .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/carlneto/OptiRoute.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: ["OptiRoute"]
        )
    ]
)
````

---

## 📚 Features

| Feature                     | Description                                                  |
| --------------------------- | ------------------------------------------------------------ |
| GPS Track Cleaning          | Remove duplicates, outliers, and prepare tracks for analysis |
| Distance & Time Calculation | Compute distances, estimated travel times, and statistics    |
| Geometric Operations        | Bearings, interpolation, centroids, midpoints, clustering    |
| MapKit Integration          | Polylines, annotations, snapshots, nearby point search       |
| Reverse Geocoding           | Convert coordinates to locality names and timezones          |

---

## 🔧 Usage Example

```swift
import OptiRoute
import MapKit

// Example: Load a track and compute distance
let track = OptiRoute.Track(gpsPoints: gpsData)
let totalDistance = track.totalDistance()
print("Total distance: \(totalDistance) meters")
```

> See full examples in the `Examples` folder.

---

## 📄 License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.
