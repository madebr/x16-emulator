cmake_minimum_required(VERSION 3.0)
project(x16emu LANGUAGES C)

option(WITH_YM2151 "Enable YM2151")

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_EXTENSIONS OFF)

if(CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "Clang" OR CMAKE_C_COMPILER_ID STREQUAL "AppleClang")
	add_compile_options(-O3 -Wall -Werror)
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
