#.rst:
#
# Enables code coverage by appending corresponding compiler flags.
#
# Variables modified (provided the corresponding language is enabled)::
#
#   CMAKE_Fortran_FLAGS
#   CMAKE_C_FLAGS
#   CMAKE_CXX_FLAGS
#
# autocmake.yml configuration::
#
#   docopt: "--coverage Enable code coverage [default: False]."
#   define: "'-DENABLE_CODE_COVERAGE={0}'.format(arguments['--coverage'])"

option(ENABLE_CODE_COVERAGE "Enable code coverage" OFF)

if(ENABLE_CODE_COVERAGE)
  if(NOT CMAKE_BUILD_TYPE STREQUAL "debug")
    message(WARNING "Code coverage results with an optimized (non-Debug) build may be misleading")
  endif()

  find_program(GCOV_PATH gcov)
  if(NOT GCOV_PATH)
    message(FATAL_ERROR "Code coverage analysis requires gcov!")
  endif()

  if(DEFINED CMAKE_Fortran_COMPILER_ID)
    if(CMAKE_Fortran_COMPILER_ID MATCHES GNU)
      set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -fprofile-arcs -ftest-coverage")
    else()
      message(FATAL_ERROR "Code coverage analysis requires the GNU Fortran compiler!")
    endif()
  endif()

  if(DEFINED CMAKE_C_COMPILER_ID)
    if(CMAKE_C_COMPILER_ID MATCHES "(Apple)?[Cc]lang")
      if(CMAKE_C_COMPILER_VERSION VERSION_LESS 3)
        message(FATAL_ERROR "Code coverage analysis on Mac OS X requires Clang version 3.0.0 or greater!")
      else()
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fprofile-arcs -ftest-coverage")
      endif()
    elseif(CMAKE_C_COMPILER_ID MATCHES GNU)
      set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fprofile-arcs -ftest-coverage")
    else()
      message(FATAL_ERROR "Code coverage analysis requires the GNU C compiler!")
    endif()
  endif()

  if(DEFINED CMAKE_CXX_COMPILER_ID)
    if(CMAKE_CXX_COMPILER_ID MATCHES "(Apple)?[Cc]lang")
      if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 3)
        message(FATAL_ERROR "Code coverage analysis on Mac OS X requires Clang version 3.0.0 or greater!")
      else()
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-arcs -ftest-coverage")
      endif()
    elseif(CMAKE_CXX_COMPILER_ID MATCHES GNU)
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-arcs -ftest-coverage")
    else()
      message(FATAL_ERROR "Code coverage analysis requires the GNU C++ compiler!")
    endif()
  endif()
endif()

# Param _targetname     The name of new the custom make target
# Param _testrunner     The name of the target which runs the tests.
#                       MUST return ZERO always, even on errors.
#                       If not, no coverage report will be created!
# Param _outputname     lcov output is generated as _outputname.info
#                       HTML report is generated in _outputname/index.html
# Optional fourth parameter is passed as arguments to _testrunner
#   Pass them in list form, e.g.: "-j;2" for -j 2
function(setup_target_for_coverage _targetname _testrunner _outputname)
  find_program(LCOV_PATH lcov)
  find_program(GENHTML_PATH genhtml)
  find_program(GCOVR_PATH gcovr PATHS ${PROJECT_SOURCE_DIR}/tests)

  if(NOT LCOV_PATH)
    message(FATAL_ERROR "Code coverage analysis requires lcov!")
  endif()

  if(NOT GENHTML_PATH)
    message(FATAL_ERROR "Code coverage analysis requires genhtml!")
  endif()

  set(coverage_info "${PROJECT_BINARY_DIR}/${_outputname}.info")
  set(coverage_cleaned "${coverage_info}.cleaned")

  separate_arguments(test_command UNIX_COMMAND "${_testrunner}")

  # Setup target
  add_custom_target(${_targetname}

    # Cleanup lcov
    ${LCOV_PATH} --directory . --zerocounters

    # Run tests
    COMMAND ${test_command} ${ARGV3}

    # Capturing lcov counters and generating report
    COMMAND ${LCOV_PATH} --directory . --capture --output-file ${coverage_info}
    COMMAND ${LCOV_PATH} --remove ${coverage_info} 'tests/*' '/usr/*' --output-file ${coverage_cleaned}
    COMMAND ${GENHTML_PATH} -o ${_outputname} ${coverage_cleaned}
    COMMAND ${CMAKE_COMMAND} -E remove ${coverage_info} ${coverage_cleaned}

    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    COMMENT "Resetting code coverage counters to zero.\nProcessing code coverage counters and generating report."
    )

  # Show info where to find the report
  add_custom_command(TARGET ${_targetname} POST_BUILD
    COMMAND ;
    COMMENT "Open ./${_outputname}/index.html in your browser to view the coverage report."
    )
endfunction()
