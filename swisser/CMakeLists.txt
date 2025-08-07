cmake_minimum_required(VERSION 3.16)

project(swisser 
    VERSION 1.0.0
    DESCRIPTION "Swisser - Swiss System Tournament Pairing Software"
    LANGUAGES CXX
)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Create the executable
#add_executable(bbpPairings ${SOURCES})

# Define source files
set(SOURCES src/swisser.cpp 
            src/validate.cpp
            src/swisssystems/common.cpp 
            src/swisssystems/dutch.cpp
            src/swisssystems/burstein.cpp
            src/swisssystems/roundrobin.cpp
            src/tournament/tournament.cpp
            src/matching/computer.cpp
            src/matching/computer.cpp
            src/matching/detail/graph.cpp
            src/matching/detail/parentblossom.cpp
            src/matching/detail/rootblossom.cpp)

add_executable(swisser ${SOURCES})

# Set output name to match Makefile
set_target_properties(swisser PROPERTIES OUTPUT_NAME "swisser")

# Include directories
target_include_directories(swisser PRIVATE src)

# Compiler flags (Linux/GCC specific, ignoring Windows flags)
target_compile_options(swisser PRIVATE
    -ftabstop=2
    -Werror
    -Wfatal-errors
    -pedantic
    -pedantic-errors
    -Wall
    -Walloca
    -Wcast-qual
    -Wctor-dtor-privacy
    -Wdisabled-optimization
    -Wdouble-promotion
    -Wextra
    -Wextra-semi
    -Wformat=2
    -Winvalid-pch
    -Wmismatched-tags
    -Wmissing-braces
    -Wmissing-declarations
    -Wmissing-include-dirs
    -Wnull-dereference
    -Woverloaded-virtual
    -Wpacked
    -Wpointer-arith
    -Wredundant-decls
    -Wsign-promo
    -Wsuggest-override
    -Wundef
    -Wunknown-pragmas
    -Wunused-macros
    -Wvla
    -Wzero-as-null-pointer-constant
    -Wno-free-nonheap-object
    -Wno-overflow
    -Wno-sign-compare
)

# GCC-specific flags (assuming GCC on Linux)
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    target_compile_options(swisser PRIVATE
        -Wabi=0
        -Waligned-new=all
        -Walloc-zero
        -Warray-bounds=2
        -Wattribute-alias=2
        -Wcatch-value=3
        -Wconditionally-supported
        -Wduplicated-cond
        -Wformat-overflow=2
        -Wformat-signedness
        -Wformat-truncation=2
        -Wimplicit-fallthrough=3
        -Wlogical-op
        -Wmultiple-inheritance
        -Wnormalized=nfkc
        -Wplacement-new=2
        -Wshadow=local
        -Wstrict-null-sentinel
        -Wstringop-overflow=4
        -Wsuggest-attribute=cold
        -Wsuggest-attribute=format
        -Wsuggest-attribute=malloc
        -Wsuggest-attribute=noreturn
        -Wsuggest-final-methods
        -Wsuggest-final-types
        -Wsync-nand
        -Wtrampolines
        -Wunsafe-loop-optimizations
        -Wvector-operation-performance
        -Wvirtual-inheritance
        -Wno-maybe-uninitialized
        -Wno-error=deprecated-declarations
    )
    
    # GCC version-specific flags
    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL "11.0")
        target_compile_options(swisser PRIVATE
            -Warray-parameter=2
            -Wctad-maybe-unsupported
            -Wenum-conversion
            -Winvalid-imported-macros
        )
    endif()
endif()

# Installation
install(TARGETS swisser
    RUNTIME DESTINATION bin
)


