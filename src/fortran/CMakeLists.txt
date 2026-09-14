#   cmake -S src/fortran -B build -DCMAKE_BUILD_TYPE=Release
#   cmake --build build
# Any failure is a build failure: no "-"-prefixed link lines, no phantom objects.
cmake_minimum_required(VERSION 3.20)
project(globgm LANGUAGES Fortran)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Debug or Release" FORCE)
endif()

find_package(netCDF-Fortran REQUIRED)

# METIS from src/scripts/build_metis.sh. metis_module.f90 passes int64 indices
# and real32 weights, so a library of any other width links and partitions wrong.
set(METIS_ROOT ${CMAKE_SOURCE_DIR}/../../build/metis CACHE PATH "METIS install prefix")
find_library(METIS_LIB metis PATHS ${METIS_ROOT}/lib NO_DEFAULT_PATH)
find_file(METIS_H metis.h PATHS ${METIS_ROOT}/include NO_DEFAULT_PATH)
if(NOT METIS_LIB OR NOT METIS_H)
  message(FATAL_ERROR "METIS not found under ${METIS_ROOT}; run src/scripts/build_metis.sh")
endif()
file(STRINGS ${METIS_H} METIS_IDX REGEX "^#define IDXTYPEWIDTH")
file(STRINGS ${METIS_H} METIS_REAL REGEX "^#define REALTYPEWIDTH")
if(NOT METIS_IDX MATCHES "IDXTYPEWIDTH 64$")
  message(FATAL_ERROR "${METIS_H}: need IDXTYPEWIDTH 64, found '${METIS_IDX}'")
endif()
if(NOT METIS_REAL MATCHES "REALTYPEWIDTH 32$")
  message(FATAL_ERROR "${METIS_H}: need REALTYPEWIDTH 32, found '${METIS_REAL}'")
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/mod)

if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
  add_compile_options(-ffree-line-length-none -fbacktrace)
  set(CMAKE_Fortran_FLAGS_DEBUG   "-O2 -g -fcheck=bounds")
  set(CMAKE_Fortran_FLAGS_RELEASE "-O3")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "Intel")
  set(CMAKE_Fortran_FLAGS_DEBUG   "-O2 -g -check bounds -traceback")
  set(CMAKE_Fortran_FLAGS_RELEASE "-O3")
else()
  message(FATAL_ERROR "Unsupported Fortran compiler: ${CMAKE_Fortran_COMPILER_ID}")
endif()

# --- shared library of modules -------------------------------------------
add_library(globgm_lib STATIC
  _library/raster_io.f90
  _library/cfn_mod.f90
  _library/utils_mod.f90
  _library/metis_enum_5.1.0.f90
  _library/metis_module.f90
)
target_link_libraries(globgm_lib PUBLIC netCDF::netcdff ${METIS_LIB})
target_include_directories(globgm_lib PUBLIC ${CMAKE_Fortran_MODULE_DIRECTORY})

# --- tools ---------------------------------------------------------------
foreach(tool datamap process_hydbas)
  add_executable(${tool} ${tool}/${tool}.f90)
  target_link_libraries(${tool} PRIVATE globgm_lib)
endforeach()

add_executable(mf6ggm mf6ggm/mf6_module.f90 mf6ggm/mf6ggm.f90)
target_link_libraries(mf6ggm PRIVATE globgm_lib)

add_executable(mf6ggmpost mf6ggmpost/mf6_post_module.f90 mf6ggmpost/mf6ggmpost.f90)
target_link_libraries(mf6ggmpost PRIVATE globgm_lib)
