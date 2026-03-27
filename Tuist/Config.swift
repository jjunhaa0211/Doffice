import ProjectDescription

let config = Config(
    compatibleXcodeVersions: .all,
    swiftVersion: "6.1",
    generationOptions: .options(
        resolveDependenciesWithSystemScm: false,
        disablePackageVersionLocking: true
    )
)
