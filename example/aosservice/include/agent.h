#pragma once

#include <string>
#include <string_view>
#include <chrono>
#include <vector>

namespace aos {

// Agent configuration
struct AgentConfig {
    std::string unit_id;
    std::string service_id;
    std::string api_endpoint = "https://aoscloud.io:10000/api/v10";
    int heartbeat_interval = 30;  // seconds
    std::string version = "1.0.0";
};

// Agent status
enum class Status {
    Starting,
    Running,
    Connecting,
    Ready,
    Error
};

const char* to_string(Status status);

// Main agent class
class Agent {
public:
    explicit Agent(const AgentConfig& config);
    ~Agent();

    // Lifecycle
    bool start();
    void stop();
    bool is_running() const { return running_; }

    // Operations
    void heartbeat();
    void report_status();
    std::string get_info() const;

private:
    AgentConfig config_;
    Status status_ = Status::Starting;
    bool running_ = false;
    std::chrono::steady_clock::time_point start_time_;

    void log(std::string_view message) const;
};

// Utility functions
std::string get_timestamp();
std::string get_hostname();
std::string get_architecture();
long get_uptime();

} // namespace aos
