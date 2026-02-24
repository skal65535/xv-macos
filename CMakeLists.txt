cmake_minimum_required(VERSION 3.10)
project(xv C)

# Define build directory for sources
set(XV_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/xv-3.10a")

# =============================================================================
# Create executables
# =============================================================================
# xv source files
set(XV_SOURCES
    ${XV_SOURCE_DIR}/xv.c
    ${XV_SOURCE_DIR}/xvevent.c
    ${XV_SOURCE_DIR}/xvroot.c
    ${XV_SOURCE_DIR}/xvmisc.c
    ${XV_SOURCE_DIR}/xvimage.c
    ${XV_SOURCE_DIR}/xvcolor.c
    ${XV_SOURCE_DIR}/xvsmooth.c
    ${XV_SOURCE_DIR}/xv24to8.c
    ${XV_SOURCE_DIR}/xvgif.c
    ${XV_SOURCE_DIR}/xvpm.c
    ${XV_SOURCE_DIR}/xvinfo.c
    ${XV_SOURCE_DIR}/xvctrl.c
    ${XV_SOURCE_DIR}/xvscrl.c
    ${XV_SOURCE_DIR}/xvalg.c
    ${XV_SOURCE_DIR}/xvgifwr.c
    ${XV_SOURCE_DIR}/xvdir.c
    ${XV_SOURCE_DIR}/xvbutt.c
    ${XV_SOURCE_DIR}/xvpbm.c
    ${XV_SOURCE_DIR}/xvxbm.c
    ${XV_SOURCE_DIR}/xvgam.c
    ${XV_SOURCE_DIR}/xvbmp.c
    ${XV_SOURCE_DIR}/xvdial.c
    ${XV_SOURCE_DIR}/xvgraf.c
    ${XV_SOURCE_DIR}/xvsunras.c
    ${XV_SOURCE_DIR}/xvjpeg.c
    ${XV_SOURCE_DIR}/xvps.c
    ${XV_SOURCE_DIR}/xvpopup.c
    ${XV_SOURCE_DIR}/xvdflt.c
    ${XV_SOURCE_DIR}/xvtiff.c
    ${XV_SOURCE_DIR}/xvtiffwr.c
    ${XV_SOURCE_DIR}/xvpds.c
    ${XV_SOURCE_DIR}/xvrle.c
    ${XV_SOURCE_DIR}/xviris.c
    ${XV_SOURCE_DIR}/xvgrab.c
    ${XV_SOURCE_DIR}/vprintf.c
    ${XV_SOURCE_DIR}/xvbrowse.c
    ${XV_SOURCE_DIR}/xvtext.c
    ${XV_SOURCE_DIR}/xvpcx.c
    ${XV_SOURCE_DIR}/xviff.c
    ${XV_SOURCE_DIR}/xvtarga.c
    ${XV_SOURCE_DIR}/xvxpm.c
    ${XV_SOURCE_DIR}/xvcut.c
    ${XV_SOURCE_DIR}/xvxwd.c
    ${XV_SOURCE_DIR}/xvfits.c
    ${XV_SOURCE_DIR}/xvpng.c
    ${XV_SOURCE_DIR}/xvzx.c
    ${XV_SOURCE_DIR}/xvwbmp.c
    ${XV_SOURCE_DIR}/xvpcd.c
    ${XV_SOURCE_DIR}/xvhips.c
    ${XV_SOURCE_DIR}/xvmag.c
    ${XV_SOURCE_DIR}/xvpic.c
    ${XV_SOURCE_DIR}/xvmaki.c
    ${XV_SOURCE_DIR}/xvpi.c
    ${XV_SOURCE_DIR}/xvpic2.c
    ${XV_SOURCE_DIR}/xvvd.c
    ${XV_SOURCE_DIR}/xvmgcsfx.c
    ${XV_SOURCE_DIR}/xvml.c
    ${XV_SOURCE_DIR}/xvjp2k.c
)

add_executable(xv ${XV_SOURCES})
add_executable(bggen ${XV_SOURCE_DIR}/bggen.c)
add_executable(vdcomp ${XV_SOURCE_DIR}/vdcomp.c)
add_executable(xcmap ${XV_SOURCE_DIR}/xcmap.c)
add_executable(xvpictoppm ${XV_SOURCE_DIR}/xvpictoppm.c)

# =============================================================================
# Helper function for conditional feature enablement
# =============================================================================
# Arguments:
#   FEATURE_NAME: The name of the feature (e.g., JPEG, TIFF, JP2K).
#                 Used for the CMake option (e.g., BUILD_JPEG) and the preprocessor macro prefix (e.g., DOJPEG).
#   LIBRARY_NAME: The name of the CMake find_package module (e.g., JPEG, TIFF, Jasper).
#   CMAKE_TARGET: The name of the CMake target to add compile definitions and link libraries to (e.g., xv).
function(enable_feature_with_library FEATURE_NAME LIBRARY_NAME CMAKE_TARGET)
    # Define a user-controllable option for this feature. Defaults to ON.
    # This allows users to disable features via CMake configuration, e.g.:
    # cmake -DBUILD_JPEG=OFF ...
    option(BUILD_${FEATURE_NAME} "Enable ${FEATURE_NAME} support" ON)

    if(BUILD_${FEATURE_NAME})
        # Attempt to find the required library.
        # We do NOT use 'REQUIRED' here so that the build can continue if the library isn't found.
        # Instead, we issue a warning.
        find_package(${LIBRARY_NAME})

        if(${LIBRARY_NAME}_FOUND)
            message(STATUS "Found ${LIBRARY_NAME}. Enabling ${FEATURE_NAME} support.")

            # Add the preprocessor definition for this feature (e.g., -DDOJPEG).
            target_compile_definitions(${CMAKE_TARGET} PRIVATE -DDO${FEATURE_NAME})

            # Automatically add include directories if the find_package module provides them.
            if(${LIBRARY_NAME}_INCLUDE_DIRS)
                target_include_directories(${CMAKE_TARGET} PRIVATE ${${LIBRARY_NAME}_INCLUDE_DIRS})
            endif()

            # Automatically link the library if the find_package module provides it.
            # Some find_package modules might only set _FOUND and not _LIBRARIES directly if they are system libraries.
            # We'll check and add if available.
            if(${LIBRARY_NAME}_LIBRARIES)
                target_link_libraries(${CMAKE_TARGET} PRIVATE ${${LIBRARY_NAME}_LIBRARIES})
            endif()

            # Explicitly link Jasper::Jasper target if found, for macOS compatibility
            if(LIBRARY_NAME STREQUAL "Jasper")
                if(TARGET Jasper::Jasper)
                    target_link_libraries(${CMAKE_TARGET} PRIVATE Jasper::Jasper)
                else()
                    # Fallback if Jasper::Jasper target is not defined by FindJasper
                    if(${LIBRARY_NAME}_LIBRARIES)
                        target_link_libraries(${CMAKE_TARGET} PRIVATE ${${LIBRARY_NAME}_LIBRARIES})
                    endif()
                endif()
            endif()
        else()
            # If the library is not found, warn the user.
            message(WARNING "Could not find ${LIBRARY_NAME}. ${FEATURE_NAME} support will be disabled. Install the development package for ${LIBRARY_NAME} if you require this feature.")
        endif()
    else()
        # If the option is explicitly turned off by the user.
        message(STATUS "${FEATURE_NAME} support disabled by user.")
    endif()
endfunction()

# =============================================================================
# Find required libraries and configure features
# =============================================================================

# Find system libraries (these are often implicitly required for other features)
find_package(X11 REQUIRED)
target_link_libraries(xv PRIVATE X11::X11) # Ensure X11 is linked with keyword signature

# Explicitly find PNG and ZLIB for system-wide libraries
find_package(PNG REQUIRED)
if(PNG_FOUND)
    message(STATUS "Found PNG. Enabling PNG support.")
    target_compile_definitions(xv PRIVATE -DHAVE_PNG)
    target_include_directories(xv PRIVATE ${PNG_INCLUDE_DIRS})
    if(TARGET PNG::libpng)
        target_link_libraries(xv PRIVATE PNG::libpng)
    else()
        target_link_libraries(xv PRIVATE ${PNG_LIBRARIES})
    endif()
else()
    message(WARNING "Could not find PNG library. PNG support will be disabled. Install libpng development package if you require this feature.")
endif()

find_package(ZLIB REQUIRED)
if(ZLIB_FOUND)
    message(STATUS "Found ZLIB. Enabling ZLIB support.")
    target_compile_definitions(xv PRIVATE -DHAVE_ZLIB)
    target_include_directories(xv PRIVATE ${ZLIB_INCLUDE_DIRS})
    if(TARGET ZLIB::zlib)
        target_link_libraries(xv PRIVATE ZLIB::zlib)
    else()
        target_link_libraries(xv PRIVATE ${ZLIB_LIBRARIES})
    endif()
else()
    message(WARNING "Could not find ZLIB library. ZLIB support will be disabled. Install zlib development package if you require this feature.")
endif()

# Configure image format support using the generic function
enable_feature_with_library(JPEG JPEG xv)
enable_feature_with_library(TIFF TIFF xv)
enable_feature_with_library(JP2K Jasper xv) # JP2K support typically relies on Jasper

# PDS/VICAR support is currently only defined in the Makefile (-DDOPDS)
# and has no explicit find_package in this CMakeLists.txt.
# To control it via CMake, we would need to define an option and potentially
# add logic to find PDS-specific headers/libraries if they are installed.
# For now, we add the option and a placeholder comment.
option(BUILD_PDS "Enable PDS/VICAR support" ON)
if(BUILD_PDS)
    # Placeholder: Add logic here to find PDS libraries/headers if available.
    # Example:
    # find_path(PDS_INCLUDE_DIR NAMES vicar.h HINTS /usr/include /usr/local/include)
    # find_library(PDS_LIBRARY NAMES vicardev HINTS /usr/lib /usr/local/lib)
    # if(PDS_INCLUDE_DIR AND PDS_LIBRARY)
    #    message(STATUS "Found PDS/VICAR libraries. Enabling PDS support.")
    #    target_compile_definitions(${CMAKE_TARGET} PRIVATE -DDOPDS)
    #    target_include_directories(${CMAKE_TARGET} PRIVATE ${PDS_INCLUDE_DIR})
    #    target_link_libraries(${CMAKE_TARGET} ${PDS_LIBRARY})
    # else()
        message(WARNING "PDS/VICAR support requested (BUILD_PDS=ON) but PDS libraries/headers not found. PDS support will be disabled. Consider configuring PDS manually if available.")
        # If PDS is crucial and must be found, uncomment the line below to fail the build.
        # find_package(PDS REQUIRED) # Hypothetical PDS find_package
    # endif()
else()
    message(STATUS "PDS/VICAR support disabled by user.")
endif()

# =============================================================================
# Include directories for xv and its dependencies
# =============================================================================
# These are added globally to the target. If format-specific includes are needed
# beyond what find_package provides, they might be added here or within the function.
include_directories(
    ${XV_SOURCE_DIR}
    ${X11_INCLUDE_DIR}
    # The include directories for JPEG, TIFF, PNG, Jasper are handled by
    # target_include_directories within the enable_feature_with_library function
    # if the find_package modules provide them.
)

# Add compiler definitions based on Makefile.std and feature enablement
# Keep Linux definition as it might be used for specific OS behaviors.
# Other definitions like DOCDIR, SYSCONFDIR, XVEXECPATH are configuration details.
target_compile_definitions(xv PRIVATE
    # These are now controlled by enable_feature_with_library function
    # -DDOTIFF
    # -DDOJPEG
    # -DDOPNG
    # -DDOJP2K
    # -DDOPDS # This will be conditionally defined by the function logic above

    -DDOCDIR="/usr/local/share/doc/xv"
    -DSYSCONFDIR="/etc"
    -DXVEXECPATH="/usr/local/lib/xv"
)

# Link libraries
# Core libraries that are always needed.
target_link_libraries(xv PRIVATE
    ${X11_LIBRARIES}
    ${X11_Xt_LIB}
    # JPEG, TIFF, PNG, Jasper, and ZLIB libraries are linked explicitly
    # or by enable_feature_with_library if they are found and enabled.
    m # for -lm
)
target_link_libraries(bggen PRIVATE ${X11_LIBRARIES} ${X11_Xt_LIB} m)
target_link_libraries(xcmap PRIVATE ${X11_LIBRARIES} ${X11_Xt_LIB} m)

install(TARGETS xv bggen vdcomp xcmap xvpictoppm DESTINATION bin)