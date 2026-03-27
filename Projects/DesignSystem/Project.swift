import ProjectDescription

let project = Project(
    name: "DesignSystem",
    settings: .settings(
        base: [
            "DEAD_CODE_STRIPPING": "YES",
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release", settings: [
                "SWIFT_OPTIMIZATION_LEVEL": "-Owholemodule",
                "SWIFT_COMPILATION_MODE": "wholemodule",
                "GCC_OPTIMIZATION_LEVEL": "s",
            ]),
        ]
    ),
    targets: [
        Target(
            name: "DesignSystem",
            platform: .macOS,
            product: .staticFramework,
            bundleId: "com.junha.doffice.designsystem",
            deploymentTarget: .macOS(targetVersion: "14.0"),
            sources: ["Sources/**"],
            dependencies: []
        ),
    ]
)
