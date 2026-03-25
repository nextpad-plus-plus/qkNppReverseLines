cmake_minimum_required(VERSION 3.20)
project(qkNppReverseLines LANGUAGES CXX OBJCXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_OBJCXX_STANDARD 17)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)

# Path to the Notepad++ macOS port for shared headers
set(NPP_MACOS_DIR "${CMAKE_SOURCE_DIR}/../../notepad-plus-plus-macos")
set(NPP_WIN_DIR "${CMAKE_SOURCE_DIR}/../../notepad-plus-plus")
set(SCINTILLA_INCLUDE "${NPP_WIN_DIR}/scintilla/include")
set(NPP_PLUGIN_INCLUDE "${NPP_MACOS_DIR}/src")

add_library(qkNppReverseLines SHARED
    src/ReverseLines.mm
)

target_link_libraries(qkNppReverseLines PRIVATE
    "-framework Cocoa"
)

target_include_directories(qkNppReverseLines PRIVATE
    ${NPP_PLUGIN_INCLUDE}
    ${SCINTILLA_INCLUDE}
)

# Output as .dylib (default on macOS for SHARED libraries)
set_target_properties(qkNppReverseLines PROPERTIES
    PREFIX ""
    SUFFIX ".dylib"
    OUTPUT_NAME "qkNppReverseLines"
)

# Install target: copy to plugins directory
set(PLUGIN_INSTALL_DIR "$ENV{HOME}/.notepad++/plugins/qkNppReverseLines")
install(TARGETS qkNppReverseLines DESTINATION "${PLUGIN_INSTALL_DIR}")
