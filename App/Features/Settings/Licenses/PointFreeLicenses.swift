extension License {
    internal static let pointFree: [License] = [
        pointFreeMIT(id: "composable-architecture", name: "The Composable Architecture", copyright: "2020 Point-Free, Inc."),
        pointFreeMIT(id: "combine-schedulers", name: "combine-schedulers", copyright: "2020 Point-Free, Inc."),
        pointFreeMIT(id: "swift-case-paths", name: "swift-case-paths", copyright: "2020 Point-Free, Inc."),
        pointFreeMIT(id: "swift-clocks", name: "swift-clocks", copyright: "2022 Point-Free"),
        pointFreeMIT(id: "swift-concurrency-extras", name: "swift-concurrency-extras", copyright: "2023 Point-Free"),
        pointFreeMIT(id: "swift-custom-dump", name: "swift-custom-dump", copyright: "2021 Point-Free, Inc."),
        pointFreeMIT(id: "swift-dependencies", name: "swift-dependencies", copyright: "2022 Point-Free, Inc."),
        pointFreeMIT(id: "swift-identified-collections", name: "swift-identified-collections", copyright: "2021 Point-Free, Inc."),
        pointFreeMIT(id: "swift-issue-reporting", name: "swift-issue-reporting", copyright: "2021 Point-Free, Inc."),
        pointFreeMIT(id: "swift-navigation", name: "swift-navigation", copyright: "2021 Point-Free, Inc."),
        pointFreeMIT(id: "swift-perception", name: "swift-perception", copyright: "2023 Point-Free"),
        pointFreeMIT(id: "swift-sharing", name: "swift-sharing", copyright: "2024 Point-Free, Inc."),
    ]

    private static func pointFreeMIT(id: String, name: String, copyright: String) -> License {
        License(id: id, name: name, kind: "MIT", note: nil, text: mitText(copyright: "Copyright (c) \(copyright)"))
    }
}
