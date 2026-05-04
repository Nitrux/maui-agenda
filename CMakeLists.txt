cmake_minimum_required(VERSION 3.16)

set(CMAKE_SUPPRESS_DEVELOPER_WARNINGS TRUE CACHE BOOL "" FORCE)

project(agenda VERSION 1.0.2)

if(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
    message(FATAL_ERROR "This project supports Linux only.")
endif()

add_compile_definitions(APP_COPYRIGHT_NOTICE="© 2022-2025 Maui Development Team")

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(CheckCXXCompilerFlag)
if(NOT CMAKE_CROSSCOMPILING)
    string(TOLOWER "${CMAKE_HOST_SYSTEM_PROCESSOR}" _host_processor)
    if(_host_processor MATCHES "^(x86_64|amd64)$")
        check_cxx_compiler_flag("-march=x86-64-v3" HAS_X86_64_V3)
        if(HAS_X86_64_V3)
            add_compile_options("$<$<COMPILE_LANGUAGE:CXX>:-march=x86-64-v3>")
        endif()
    endif()
endif()

set(QT_MAJOR_VERSION 6)

set(REQUIRED_QT_VERSION 6.5.2)
set(REQUIRED_KF_VERSION 5.240.0)

set(PROJECT_URI "org.kde.${PROJECT_NAME}")
add_definitions(-DPROJECT_URI="${PROJECT_URI}")

find_package(ECM ${REQUIRED_KF_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(ECMInstallIcons)
include(ECMAddAppIcon)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(KDEClangFormat)
include(ECMSetupVersion)
include(ECMSourceVersionControl)
include(FeatureSummary)

find_package(Qt6 ${REQUIRED_QT_VERSION} REQUIRED COMPONENTS Core Quick Qml Widgets QuickControls2)
find_package(KF6 ${REQUIRED_KF_VERSION} REQUIRED COMPONENTS I18n CoreAddons)

find_package(MauiKit4 REQUIRED COMPONENTS Calendar)

if(ECM_SOURCE_UNDER_VERSION_CONTROL)
    execute_process(
        COMMAND git rev-parse --abbrev-ref HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_BRANCH
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    # Get the latest abbreviated commit hash of the working branch
    execute_process(
        COMMAND git log -1 --format=%h
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_COMMIT_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    add_definitions(-DGIT_COMMIT_HASH="${GIT_COMMIT_HASH}")
    add_definitions(-DGIT_BRANCH="${GIT_BRANCH}")

else()
    add_definitions(-DGIT_COMMIT_HASH="${PROJECT_VERSION}")
    add_definitions(-DGIT_BRANCH="${CMAKE_BUILD_TYPE}")
endif()

ecm_setup_version(${PROJECT_VERSION}
    VARIABLE_PREFIX PROJECT
    VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/project_version.h")

add_subdirectory(src)

ki18n_install(po)

install(FILES org.kde.agenda.metainfo.xml  DESTINATION ${KDE_INSTALL_METAINFODIR})

install(FILES src/org.kde.agenda.desktop DESTINATION ${KDE_INSTALL_APPDIR})

install(FILES src/assets/logo.svg DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/scalable/apps RENAME ${PROJECT_NAME}.svg)

#install(FILES data/org.kde.index.notifyrc DESTINATION ${KNOTIFYRC_INSTALL_DIR})

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)

file(GLOB_RECURSE ALL_CLANG_FORMAT_SOURCE_FILES *.cpp *.h)
kde_clang_format(${ALL_CLANG_FORMAT_SOURCE_FILES})


if(NOT TARGET uninstall)
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
        "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
        IMMEDIATE
        @ONLY)

    add_custom_target(uninstall
        COMMAND ${CMAKE_COMMAND} -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake")
endif()
