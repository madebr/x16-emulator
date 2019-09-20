cmake_minimum_required(VERSION 3.0)
project(x16emu LANGUAGES C VERSION 32)

option(BUILD_DOCS "Build documentation")
option(WITH_YM2151 "Enable YM2151")
option(X16EMU_RELEASE "This is a x16-emu release")
set(X16ROM_PATH "" CACHE PATH "Path to x16-rom")
set(X16DOCS_PATH "" CACHE PATH "Path to x16-docs")

if(X16EMU_RELEASE)
	message(STATUS "This is a release build")
	set(BUILD_DOCS ON FORCE)
	set(WITH_YM2151 ON FORCE)
else()
	message(STATUS "Development build")
endif()

if(BUILD_DOCS)
	if(NOT X16ROM_PATH)
		message(FATAL_ERROR "Missing path to x16-rom. (X16ROM_PATH not set)")
	endif()

	if(NOT X16DOCS_PATH)
		message(FATAL_ERROR "Missing path to x16-docs. (X16DOCS_PATH not set)")
	endif()
endif()

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_EXTENSIONS OFF)

if(CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "Clang" OR CMAKE_C_COMPILER_ID STREQUAL "AppleClang")
	add_compile_options(-O3 -Wall -Werror)
	if(WIN32)
		# CMake 3.13 added add_link_options
		set(CMAKE_EXE_LINKER_FLAGS "-Wl,--subsystem,console")
	endif()
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")
find_package(SDL2 REQUIRED)
if(MSVC)
	include_directories("${CMAKE_CURRENT_LIST_DIR}/support/msvc/include")
endif()

find_file(ROM_LABELS rom_labels.h PATHS ${CMAKE_CURRENT_SOURCE_DIR} NO_DEFAULT_PATH)

set(SOURCES 
	cpu/fake6502.c
	debugger.c
	disasm.c
	loadsave.c
	main.c
	memory.c
	ps2.c
	sdcard.c
	spi.c
	vera_spi.c
	via.c
	video.c
	$<$<BOOL:${WITH_YM2151}>:ym2151.c>
)
set(HEADERS
	cpu/fake6502.h
	debugger.h
	disasm.h
	glue.h
	loadsave.h
	memory.h
	ps2.h
	sdcard.h
	spi.h
	utf8.h
	vera_spi.h
	via.h
	video.h
	$<$<BOOL:${ROM_LABELS}>:${ROM_LABELS}>
)

add_executable(x16emu ${SOURCES} ${HEADERS})
target_link_libraries(x16emu PRIVATE SDL2::SDL2)
if(NOT MSVC)
	target_link_libraries(x16emu PRIVATE m)
endif()
target_compile_definitions(x16emu PRIVATE $<$<BOOL:${WITH_YM2151}>:WITH_YM2151>)
install(TARGETS x16emu RUNTIME DESTINATION ".")
if(X16EMU_RELEASE OR EXISTS "${X16ROM_PATH}/rom.bin")
	add_custom_command(TARGET x16emu POST_BUILD
		COMMAND "${CMAKE_COMMAND}" -E copy "${X16ROM_PATH}/rom.bin" "${CMAKE_CURRENT_BINARY_DIR}/rom.bin"
		COMMENT "Copying rom.bin to build directory" VERBATIM)
	install(FILES "${X16ROM_PATH}/rom.bin" "${X16ROM_PATH}/rom.txt" DESTINATION ".")
endif()

if(BUILD_DOCS)
	find_package(pandoc REQUIRED)
	set(DOCS_CREATED)

	add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/docs"
		COMMAND "${CMAKE_COMMAND}" -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/docs")
	add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/docs/github-pandoc.css"
		COMMAND "${CMAKE_COMMAND}" -E copy "${CMAKE_CURRENT_SOURCE_DIR}/github-pandoc.css" "${CMAKE_CURRENT_BINARY_DIR}/docs/github-pandoc.css")
	set(DOCS_CREATED "${DOCS_CREATED};${CMAKE_CURRENT_BINARY_DIR}/docs/github-pandoc.css")

	macro(add_documentation INPUT OUTPUT TITLE)
		pandoc_gfm_to_html_generate(INPUT "${INPUT}" OUTPUT "${OUTPUT}" TITLE "${TITLE}" CSS "github-pandoc.css")
		set(DOCS_CREATED "${DOCS_CREATED};${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT}")
	endmacro()

	add_documentation("README.md" "docs/README.html" "Commander X16 Emulator")
	add_documentation("${X16ROM_PATH}/README.md" "docs/KERNAL-BASIC.html" "Commander X16 KERNAL/BASIC/DOS ROM")
	add_documentation("${X16DOCS_PATH}/Commander X16 Programmer's Reference Guide.md" "docs/Programmer's Reference Guide.html" "Commander X16 Programmer's Reference Guide")
	add_documentation("${X16DOCS_PATH}/VERA Programmer's Reference.md" "docs/VERA Programmer's Reference.html" "VERA Programmer's Reference")

	add_custom_target(docs ALL DEPENDS ${DOCS_CREATED})
	install(FILES ${DOCS_CREATED} DESTINATION "doc")
endif()

set(PACKAGE_PLATFORM "-${CMAKE_SYSTEM_NAME}")
if(EMSCRIPTEN)
	set(PACKAGE_ARCH "")
else()
	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(PACKAGE_ARCH "-x86_64")
	else()
		set(PACKAGE_ARCH "-x86")
	endif()
endif()
set(PACKAGE_VERSION "")
if(X16EMU_RELEASE)
	set(PACKAGE_VERSION "-v${PROJECT_VERSION}")
endif()

set(CPACK_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}${PACKAGE_PLATFORM}${PACKAGE_ARCH}${PACKAGE_VERSION}")
include(CPack)
