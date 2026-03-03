#include <iostream>
#include <string>
#include <vector>
#include <optional>

// C++17: std::optional example
std::optional<std::string> get_greeting(bool formal) {
    if (formal) {
        return "Good day, World!";
    }
    return std::nullopt;
}

int main() {
    std::cout << "========================================" << std::endl;
    std::cout << "Hello, World!" << std::endl;
    std::cout << "Built with Docker C++ Builder" << std::endl;
    std::cout << "C++ Standard: C++17" << std::endl;
    std::cout << "========================================" << std::endl;

    // Demonstrate C++17 features
    std::vector<int> numbers = {1, 2, 3, 4, 5};

    // C++17 if-initializer
    if (auto msg = get_greeting(true); msg.has_value()) {
        std::cout << *msg << std::endl;
    }

    // C++17 structured bindings
    std::cout << "\nVector contents:" << std::endl;
    for (const auto& number : numbers) {
        std::cout << "  - " << number << std::endl;
    }

    // C++17 constexpr if
    auto print_size = [](const auto& container) {
        if constexpr (std::is_same_v<std::decay_t<decltype(container)>, std::vector<int>>) {
            std::cout << "Vector size: " << container.size() << std::endl;
        }
    };
    print_size(numbers);

    return 0;
}
