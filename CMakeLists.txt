cmake_minimum_required(VERSION 3.16)
project(cpp_backtester VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Find nlohmann_json if available (optional but recommended for config parsing)
find_package(nlohmann_json QUIET)

include_directories(${CMAKE_SOURCE_DIR}/include)

add_executable(bt_run
    src/main.cpp
    src/data_handler.cpp
    src/strategy.cpp
    src/execution.cpp
    src/portfolio.cpp
    src/reporting.cpp
)

if (nlohmann_json_FOUND)
    target_link_libraries(bt_run PRIVATE nlohmann_json::nlohmann_json)
else()
    message(WARNING "nlohmann_json not found; ensure you provide configs/default_config.json in simple JSON form or add the single-header nlohmann json to include path.")
endif()