# SideCMake
A robust and practical CMake module collection to simplify your C++ builds.

## What the project does
SideCMake is a robust collection of CMake modules designed to simplify and modernize C++ build systems. It enables target-oriented, modular, and maintainable CMake scripts for multi-project and multi-target C++ codebases. SideCMake is intended to be used as a submodule, so your build logic stays up-to-date and easy to maintain.

## Why the project is useful
- **Submodule-based**: SideCMake is designed to be continuously updated as a submodule, not a static template.
- **Target-centered**: Focuses on C++ targets (executables/libraries) and supports clustered projects.
- **IDE-friendly**: Works seamlessly with major IDEs supporting CMake (VSCode, CLion, Visual Studio).
- **Easy package management**: Simplifies dependency setup and management via CMake scripts.
- **Easy desktop packaging support**: making SideCmake simpler for users to package desktop applications efficiently.
- **Modern C++ support**: Out-of-the-box support for C++11/14/17/20/23.
- **Testing with doctest**: supporting all major C++ standards with a single header for quick and easy setup
- **Enhanced documentation with Doxygen and Sphinx**: enable more comprehensive and maintainable code documentation.

## How users can get started
### Quick Start
1. First you need to clone SideCMake:
The recommented way is to put SideCMake aside with your project:
```sh
git clone https://github.com/imlinkzuz/SideCMake
```
an other way to use SideCMake is to put SideCMake as a submodule of your project:
```sh
cd sample-project
git init .
git submodule add https://github.com/imlinkzuz/SideCMake
```sh
2. Copy all files from `/path/to/SideCMake/bootstrap` to your project root:
```sh
cp -r /path/to/SideCMake/bootstrap/. /path/to/project/.
```
4. Configure these files to meet your needs:
Open LocalPresets.json, change SIDECMAKE_DIR to the root path of SideCMake or delete it if you prefer to use SideCMake as a submodule.
Also modify ProjectPresets.json, make sure it matches with your project's information. 
5. Prepare your source structure:
```sh
mkdir include
mkdir src
```
Add CMakeList.txt in src with contents:
```

```

### Directory Structure
#### Project Directory Structure
It is best practice to separate `include` and `src` directories at the root level.
##### Simple
```
.
├── include
│   ├── file1.h
│   ├── file2.h
│   └── ...
├── src
│   ├── CMakeLists.txt 
│   ├── file1.cpp
│   ├── file2.cpp
│   └── ...
├── CMakeLists.txt 
└── ... 
```
##### Multi Targets
```
.
├── include
│   ├── targetA
│   │   ├── file1.h
│   │   ├── file2.h
│   │   └── ...
│   └── targetB
│   │   ├── file1.h
│   │   ├── file2.h
│   │   └── ...
├── src
│   ├── targetA
│   │   ├── CMakeLists.cpp
│   │   ├── file1.cpp
│   │   └── ...
│   └── targetB
│   │   ├── CMakeLists.cpp
│   │   ├── file1.cpp
│   │   └── ...
├── CMakeLists.txt 
└── ... 
```
##### Multi Projects
Logical relationship between projects and targets in a sample:
```
.
└── projectMain
    ├-- targetMain
    ├-- targetMain1
    ├── projectA
    │    ├── projectA1
    │    ├── projectA2
    │    └── projectA3
    └── projectB
```
Project directory layout for the above sample:
```
.
├── include
│   ├── targetMain
│   │   └── ...
│   └── targetMain1
│       └── ... 
├── src
│   ├── targetMain
│   │   └── ...
│   └── targetMain1
│       └── ...
├── projectA
│   ├── CMakeList.txt 
│   ├── include
│   │   └── ...
│   ├── src
│   │   ├── CMakeList.txt 
│   │   └── ...
│   ├── projectA1
│   │   ├── CMakeList.txt 
│   │   ├── include
│   │   │   └── ...
│   │   └── src
│   │       ├── CMakeList.txt
│   │       └── ...
│   ├── projectA2
│   ├── projectA3
│   └── ...
├── projectB
│   ├── include
│   │   └── ...
│   └── src
│       ├── CMakeList.txt
│       └── ...
└── CMakeLists.txt
```
#### Deployed Directory Structure
##### Flat vs Hierarchical
The root project is named 'mainProject'.
'projectA' is a subproject of 'mainProject'.
'projectB' is a subproject of 'projectA'.
'targetMain' is a target of 'mainProject'.
'targetA' is a target of 'projectA'.
'targetB' is a target of 'projectB'.
Logical relationship according to the above description:
```
.
└── projectMain
    ├-- targetMain
    └── projectA
        ├── targetA
        └── projectB
            ├── targetB
            └── ...
```
Installed destination directory layout for the above sample:
```
.
├── include
│   └── <mapping from source>
├── bin
│   ├── executable of targetMain
│   ├── executable of targetA
│   └── executable of targetB
├── lib
│   ├── library of targetMain
│   ├── library of targetA
│   ├── library of targetB
│   └── cmake
│       ├── projectMain
│       │   ├── projectMainConfig.cmake 
│       │   ├── projectMainConfigVersion.cmake 
│       │   └── projectMainTargets.cmake
│       ├── projectA 
│       │   ├── projectAConfig.cmake 
│       │   ├── projectAConfigVersion.cmake 
│       │   └── projectATargets.cmake
│       └── projectB
│           ├── projectBConfig.cmake 
│           ├── projectBConfigVersion.cmake 
│           └── projectBTargets.cmake
├── doc
│   ├-- projectMain
│   │   ├── index.html
│   │   └── ...
│   ├-- projectA
│   │   ├── index.html
│   │   └── ...
│   └── projectB
│       ├── index.html
│       └── ...
└── ... 
```

### Configuration for SideCMake
#### Product, Project, and Target
Before detailing all configurable variables in SideCMake, it's important to clarify the hierarchy:
```
Product
    └── Project
        └── Target
```
#### Preset Files
CMake is a scripting language for declaring and configuring build processes. SideCMake goes further by using three levels of presets to simplify configuration. The top level is `CMakePresets.json`, which holds fixed presets for SideCMake. The second level is `ProjectPresets.json`, which is project-wide and freely adjustable. The third level is `LocalPresets.json`, which is specific to each developer's local system.
*** You can also use `CMakeUserPresets.json` on top of `CMakePresets.json`. ***
#### Preset Variables
See `SCInitVariables.cmake`.
#### Packages/Dependency Setup
Use `sc_find_package()` in `Dependencies.cmake`.

### Using SideCMake in IDEs
#### VSCode
1. Make sure the 'C/C++ Extension Pack' extension is installed.
2. Create a project following the Quick Start instructions.
3. Open your project folder in VSCode.

## Where users can get help
- **Example**: See [SideCMake Sample](https://www.github.com/imlinkzuz/SideCMakeExamples)
- **Issues**: Use the [GitHub Issues](../../issues) page for bug reports and feature requests.

> Special thanks to [cmake-template](https://github.com/cpp-best-practices/cmake_template) for inspiration: I used it as bootstrap template for several projects. Eventually, I realized I had made many modifications to cmake-template in my projects, so I decided to start a new C++ CMake module based on cmake-template.