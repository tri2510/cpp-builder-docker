#include "agent.h"
#include "unit_info.h"
#include <iostream>
#include <cstdlib>
#include <csignal>
#include <memory>
#include <thread>
#include <chrono>

// Global agent pointer for signal handler
std::unique_ptr<aos::Agent> g_agent;
volatile bool g_shutdown = false;

void signal_handler(int signal) {
    std::cout << "\nReceived signal " << signal << ", shutting down..." << std::endl;
    g_shutdown = true;
    if (g_agent) {
        g_agent->stop();
    }
}

void print_banner() {
    std::cout << "\n";
    std::cout << "╔═══════════════════════════════════════════════════════════╗\n";
    std::cout << "║                                                           ║\n";
    std::cout << "║              AosEdge Agent v1.0.0                         ║\n";
    std::cout << "║                                                           ║\n";
    std::cout << "║           C++ Edge Device Agent for AosCloud              ║\n";
    std::cout << "║                                                           ║\n";
    std::cout << "╚═══════════════════════════════════════════════════════════╝\n";
    std::cout << std::endl;
}

void print_usage(const char* program) {
    std::cout << "Usage: " << program << " [options]\n\n";
    std::cout << "Options:\n";
    std::cout << "  --unit-id <id>      Unit ID (default: auto-generated)\n";
    std::cout << "  --service-id <id>   Service ID (default: aos-agent)\n";
    std::cout << "  --api-url <url>     API endpoint (default: https://aoscloud.io:10000/api/v10)\n";
    std::cout << "  --interval <sec>    Heartbeat interval (default: 30)\n";
    std::cout << "  --info              Show unit info and exit\n";
    std::cout << "  --help              Show this help\n";
    std::cout << std::endl;
}

int main(int argc, char* argv[]) {
    // Parse command line arguments
    aos::AgentConfig config;
    bool show_info = false;

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--help" || arg == "-h") {
            print_banner();
            print_usage(argv[0]);
            return 0;
        } else if (arg == "--unit-id" && i + 1 < argc) {
            config.unit_id = argv[++i];
        } else if (arg == "--service-id" && i + 1 < argc) {
            config.service_id = argv[++i];
        } else if (arg == "--api-url" && i + 1 < argc) {
            config.api_endpoint = argv[++i];
        } else if (arg == "--interval" && i + 1 < argc) {
            config.heartbeat_interval = std::atoi(argv[++i]);
        } else if (arg == "--info") {
            show_info = true;
        }
    }

    print_banner();

    // Set defaults
    if (config.unit_id.empty()) {
        config.unit_id = aos::get_hostname() + "-" + aos::get_architecture();
    }
    if (config.service_id.empty()) {
        config.service_id = "aos-agent";
    }

    // Show unit info and exit if requested
    if (show_info) {
        auto unit_info = aos::UnitInfo::gather();
        std::cout << "=== Unit Information ===\n";
        std::cout << unit_info.to_json() << std::endl;
        return 0;
    }

    // Setup signal handlers
    std::signal(SIGINT, signal_handler);
    std::signal(SIGTERM, signal_handler);

    // Create and start agent
    g_agent = std::make_unique<aos::Agent>(config);

    std::cout << "Configuration:\n";
    std::cout << "  Unit ID:      " << config.unit_id << "\n";
    std::cout << "  Service ID:   " << config.service_id << "\n";
    std::cout << "  API Endpoint: " << config.api_endpoint << "\n";
    std::cout << "  Heartbeat:    " << config.heartbeat_interval << "s\n";
    std::cout << "  Version:      " << config.version << "\n";
    std::cout << std::endl;

    if (!g_agent->start()) {
        std::cerr << "Failed to start agent!" << std::endl;
        return 1;
    }

    // Main loop
    std::cout << "Agent running. Press Ctrl+C to stop.\n" << std::endl;

    while (g_agent->is_running() && !g_shutdown) {
        g_agent->heartbeat();
        g_agent->report_status();

        // Sleep for heartbeat interval
        for (int i = 0; i < config.heartbeat_interval && !g_shutdown; ++i) {
            std::this_thread::sleep_for(std::chrono::seconds(1));
        }
    }

    std::cout << "\nAgent stopped." << std::endl;
    return 0;
}
