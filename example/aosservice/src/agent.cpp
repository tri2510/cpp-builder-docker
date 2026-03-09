#include "agent.h"
#include "unit_info.h"
#include <iostream>
#include <iomanip>
#include <sstream>
#include <ctime>
#include <thread>

namespace aos {

const char* to_string(Status status) {
    switch (status) {
        case Status::Starting:  return "Starting";
        case Status::Running:   return "Running";
        case Status::Connecting: return "Connecting";
        case Status::Ready:     return "Ready";
        case Status::Error:     return "Error";
        default:                return "Unknown";
    }
}

Agent::Agent(const AgentConfig& config)
    : config_(config)
    , start_time_(std::chrono::steady_clock::now())
{
}

Agent::~Agent() {
    stop();
}

bool Agent::start() {
    log("Starting AosEdge Agent...");
    status_ = Status::Running;

    // Simulate connection to AosEdge API
    log("Connecting to " + config_.api_endpoint);
    status_ = Status::Connecting;

    // In real implementation, would authenticate and register
    log("Connected successfully");
    status_ = Status::Ready;

    return true;
}

void Agent::stop() {
    if (!running_) return;

    log("Stopping agent...");
    status_ = Status::Running;
    running_ = false;
}

void Agent::heartbeat() {
    auto uptime = std::chrono::duration_cast<std::chrono::seconds>(
        std::chrono::steady_clock::now() - start_time_
    ).count();

    std::cout << "[" << get_timestamp() << "] "
              << "Heartbeat | Unit: " << config_.unit_id
              << " | Uptime: " << uptime << "s"
              << " | Status: " << to_string(status_)
              << std::endl;
}

void Agent::report_status() {
    // In real implementation, would POST to AosEdge API
    // POST /api/v10/units/{unit_id}/status
}

std::string Agent::get_info() const {
    std::ostringstream oss;
    oss << "Agent Information:\n";
    oss << "  Version:     " << config_.version << "\n";
    oss << "  Unit ID:     " << config_.unit_id << "\n";
    oss << "  Service ID:  " << config_.service_id << "\n";
    oss << "  API:         " << config_.api_endpoint << "\n";
    oss << "  Status:      " << to_string(status_) << "\n";
    oss << "  Uptime:      "
        << std::chrono::duration_cast<std::chrono::seconds>(
            std::chrono::steady_clock::now() - start_time_
        ).count() << "s\n";
    return oss.str();
}

void Agent::log(std::string_view message) const {
    std::cout << "[" << get_timestamp() << "] "
              << "[" << config_.unit_id << "] "
              << message << std::endl;
}

// Utility functions
std::string get_timestamp() {
    auto now = std::chrono::system_clock::now();
    auto time = std::chrono::system_clock::to_time_t(now);

    std::ostringstream oss;
    oss << std::put_time(std::localtime(&time), "%Y-%m-%d %H:%M:%S");
    return oss.str();
}

std::string get_hostname() {
    // In real implementation, would get actual hostname
    // For now, return a placeholder
    return "aos-unit-001";
}

std::string get_architecture() {
    #if defined(__x86_64__) || defined(_M_X64)
        return "amd64";
    #elif defined(__aarch64__) || defined(_M_ARM64)
        return "arm64";
    #elif defined(__arm__) || defined(_M_ARM)
        return "armhf";
    #else
        return "unknown";
    #endif
}

long get_uptime() {
    // Would return actual system uptime
    return 0;
}

} // namespace aos
