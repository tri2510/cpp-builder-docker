#pragma once

#include <string>
#include <unordered_map>
#include <optional>

namespace aos {

// Unit (device) information reported to AosEdge
struct UnitInfo {
    // Identification
    std::string system_uid;
    std::string hostname;
    std::string unit_type;

    // Hardware
    std::string architecture;
    std::string cpu_model;
    int cpu_cores = 0;
    std::size_t memory_mb = 0;

    // Software
    std::string os_version;
    std::string agent_version;
    std::string service_version;

    // Network
    std::string ip_address;
    std::string mac_address;

    // Status
    std::string status = "online";
    long uptime_seconds = 0;

    // Convert to JSON string for API
    std::string to_json() const;

    // Populate with system information
    static UnitInfo gather();
};

// Service information for deployment
struct ServiceInfo {
    std::string service_id;
    std::string label;
    std::string version;
    std::string checksum;

    std::string to_json() const;
};

} // namespace aos
