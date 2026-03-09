#include "unit_info.h"
#include "agent.h"
#include <sstream>
#include <iomanip>
#include <fstream>

namespace aos {

std::string UnitInfo::to_json() const {
    std::ostringstream oss;
    oss << "{\n";
    oss << "  \"system_uid\": \"" << system_uid << "\",\n";
    oss << "  \"hostname\": \"" << hostname << "\",\n";
    oss << "  \"unit_type\": \"" << unit_type << "\",\n";
    oss << "  \"architecture\": \"" << architecture << "\",\n";
    oss << "  \"cpu_model\": \"" << cpu_model << "\",\n";
    oss << "  \"cpu_cores\": " << cpu_cores << ",\n";
    oss << "  \"memory_mb\": " << memory_mb << ",\n";
    oss << "  \"os_version\": \"" << os_version << "\",\n";
    oss << "  \"agent_version\": \"" << agent_version << "\",\n";
    oss << "  \"service_version\": \"" << service_version << "\",\n";
    oss << "  \"ip_address\": \"" << ip_address << "\",\n";
    oss << "  \"status\": \"" << status << "\",\n";
    oss << "  \"uptime_seconds\": " << uptime_seconds << "\n";
    oss << "}";
    return oss.str();
}

UnitInfo UnitInfo::gather() {
    UnitInfo info;

    // Identification
    info.hostname = get_hostname();
    info.system_uid = info.hostname + "-" + get_architecture();
    info.unit_type = "edge-device";

    // Hardware
    info.architecture = get_architecture();
    info.cpu_model = "Unknown";
    info.cpu_cores = 1;  // Would detect actual cores
    info.memory_mb = 1024;  // Would detect actual memory

    // Software
    info.os_version = "Linux 6.8.0";
    info.agent_version = "1.0.0";
    info.service_version = "1.0.0";

    // Network
    info.ip_address = "192.168.1.100";  // Would detect actual IP
    info.mac_address = "00:00:00:00:00:00";  // Would detect actual MAC

    // Status
    info.status = "online";
    info.uptime_seconds = get_uptime();

    return info;
}

std::string ServiceInfo::to_json() const {
    std::ostringstream oss;
    oss << "{\n";
    oss << "  \"service_id\": \"" << service_id << "\",\n";
    oss << "  \"label\": \"" << label << "\",\n";
    oss << "  \"version\": \"" << version << "\",\n";
    oss << "  \"checksum\": \"" << checksum << "\"\n";
    oss << "}";
    return oss.str();
}

} // namespace aos
