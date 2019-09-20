set(CMAKE_SYSTEM_NAME Windows)

if(NOT CMAKE_C_COMPILER)
	if("$ENV{CC}" STREQUAL "")
		message(FATAL_ERROR "Need CC environment variable")
	endif()

	set(CMAKE_C_COMPILER "$ENV{CC}")
endif()

execute_process(COMMAND "$ENV{CC}" -print-sysroot
	RESULTS_VARIABLE CC_SYSROOT_RESULT
	OUTPUT_VARIABLE CC_SYSROOT_OUTPUT)
string(STRIP "${CC_SYSROOT_OUTPUT}" CC_SYSROOT_OUTPUT)

if(GCC_SYSROOT_RESULT)
	message(FATAL_ERROR "Could not determine sysroot")
endif()

set(CMAKE_FIND_ROOT_PATH
	${CC_SYSROOT_OUTPUT}
	${CC_SYSROOT_OUTPUT}/mingw
)

# search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
