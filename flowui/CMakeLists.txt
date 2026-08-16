cmake_minimum_required(VERSION 3.16)

project(flowui VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.10)

# Content of downloaded design from Figma to Qt or similar
if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/importedcontent/CMakeLists.txt")
    add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/importedcontent)
endif()

# Generate Windows Resource file with absolute path to icon file
set(ICON_FILE "${CMAKE_CURRENT_SOURCE_DIR}/../flowicon/flowicon.ico")
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/appicon.rc" "IDI_ICON1 ICON DISCARDABLE \"${ICON_FILE}\"\n")

qt_add_executable(appflowui
    main.cpp
    DBController.cpp
    DBController.hpp
    ../db/DBManager.cpp
    ../engine/ASTNode.cpp
    ../engine/Evaluator.cpp
    ../engine/Lexer.cpp
    ../engine/Parser.cpp
    ../engine/Token.cpp
    "${CMAKE_CURRENT_BINARY_DIR}/appicon.rc"
)

target_include_directories(appflowui PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/../db
    ${CMAKE_CURRENT_SOURCE_DIR}/../engine
)

qt_add_qml_module(appflowui
    URI flowui
    QML_FILES
        Main.qml
        RESOURCES
        QML_FILES Bgdash.qml
        QML_FILES MIDblock.qml
        QML_FILES IDblock.qml
        QML_FILES SubIDblock.qml
        QML_FILES Appmenu.qml
        QML_FILES Wheeldate.qml
        QML_FILES Yearset.qml
        QML_FILES
        QML_FILES Selectdate.qml
        QML_FILES
        QML_FILES
        QML_FILES
        QML_FILES Funcbox.qml
        QML_FILES
        QML_FILES Reportblock.qml
        QML_FILES Starttitle.qml
        QML_FILES Categoryset.qml
        QML_FILES Colorset.qml
        QML_FILES Rightdash.qml
        QML_FILES Wheelday.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appflowui PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appflowui
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appflowui
    PRIVATE Qt6::Quick
)

add_executable(launcher launcher.cpp "${CMAKE_CURRENT_BINARY_DIR}/appicon.rc")
set_target_properties(launcher PROPERTIES WIN32_EXECUTABLE TRUE)

add_executable(updater updater.cpp)
target_link_libraries(updater PRIVATE wininet)

install(TARGETS appflowui launcher updater
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
