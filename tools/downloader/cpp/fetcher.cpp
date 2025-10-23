#include <iostream>
#include <string>
#include <fstream>
#include <sstream>
#include <vector>
#include <map>
#include <filesystem>
#include <curl/curl.h>
#include <ctime>
#include <iomanip>

// Simple HTTP client using libcurl
class HttpClient {
public:
    static std::string get(const std::string& url) {
        CURL* curl;
        CURLcode res;
        std::string response;
        
        curl = curl_easy_init();
        if (curl) {
            curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);
            curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
            curl_easy_setopt(curl, CURLOPT_USERAGENT, "C++ Backtester Data Fetcher/1.0");
            curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
            curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0L);
            
            res = curl_easy_perform(curl);
            curl_easy_cleanup(curl);
            
            if (res != CURLE_OK) {
                throw std::runtime_error("HTTP request failed: " + std::string(curl_easy_strerror(res)));
            }
        }
        
        return response;
    }
    
private:
    static size_t WriteCallback(void* contents, size_t size, size_t nmemb, std::string* userp) {
        size_t totalSize = size * nmemb;
        userp->append((char*)contents, totalSize);
        return totalSize;
    }
};

// Simple CSV data generator for testing
class TestDataGenerator {
public:
    static bool generateTestData(const std::string& symbol, const std::string& outputDir) {
        try {
            std::cout << "Generating test data for " << symbol << "..." << std::endl;
            
            // Create output directory
            std::filesystem::create_directories(outputDir);
            
            // Generate 2 years of daily data
            std::vector<std::string> csvLines;
            csvLines.push_back("Date,Open,High,Low,Close,Adj Close,Volume");
            
            // Start date: 2 years ago
            time_t now = time(0);
            time_t startTime = now - (2 * 365 * 24 * 60 * 60); // 2 years ago
            
            double basePrice = 100.0;
            double price = basePrice;
            
            for (int i = 0; i < 500; ++i) { // ~2 years of trading days
                time_t currentTime = startTime + (i * 24 * 60 * 60);
                struct tm* timeinfo = localtime(&currentTime);
                
                // Skip weekends (Saturday = 6, Sunday = 0)
                if (timeinfo->tm_wday == 0 || timeinfo->tm_wday == 6) {
                    continue;
                }
                
                char dateStr[11];
                strftime(dateStr, sizeof(dateStr), "%Y-%m-%d", timeinfo);
                
                // Generate realistic price movement
                double change = ((rand() % 200) - 100) / 1000.0; // -10% to +10% change
                price *= (1.0 + change);
                
                // Ensure price stays positive
                if (price < 1.0) price = 1.0;
                
                double open = price;
                double high = price * (1.0 + (rand() % 50) / 1000.0);
                double low = price * (1.0 - (rand() % 50) / 1000.0);
                double close = price;
                long volume = 1000000 + (rand() % 5000000);
                
                std::ostringstream line;
                line << dateStr << ","
                     << std::fixed << std::setprecision(2) << open << ","
                     << std::fixed << std::setprecision(2) << high << ","
                     << std::fixed << std::setprecision(2) << low << ","
                     << std::fixed << std::setprecision(2) << close << ","
                     << std::fixed << std::setprecision(2) << close << ","
                     << volume;
                
                csvLines.push_back(line.str());
            }
            
            // Write to file
            std::string outputFile = outputDir + "/" + symbol + ".csv";
            std::ofstream file(outputFile);
            
            if (!file.is_open()) {
                std::cerr << "Failed to open output file: " << outputFile << std::endl;
                return false;
            }
            
            for (const auto& line : csvLines) {
                file << line << std::endl;
            }
            
            file.close();
            
            std::cout << "Successfully generated " << csvLines.size() - 1 << " records to " << outputFile << std::endl;
            return true;
            
        } catch (const std::exception& e) {
            std::cerr << "Error generating test data: " << e.what() << std::endl;
            return false;
        }
    }
};

// Simple data fetcher that uses Python scripts
class DataFetcher {
public:
    static bool fetchData(const std::string& symbol, const std::string& source, 
                         const std::string& apiKey, const std::string& outputDir) {
        try {
            std::cout << "Fetching data for " << symbol << " using " << source << "..." << std::endl;
            
            // Create output directory
            std::filesystem::create_directories(outputDir);
            
            std::string command;
            if (source == "yahoo") {
                command = "python3 tools/downloader/python/fetch_yahoo.py " + symbol + " " + outputDir;
            } else if (source == "alpha-vantage") {
                if (apiKey.empty()) {
                    std::cerr << "API key required for Alpha Vantage" << std::endl;
                    return false;
                }
                command = "python3 tools/downloader/python/fetch_alpha_vantage.py " + symbol + " " + apiKey + " " + outputDir;
            } else {
                std::cerr << "Unknown data source: " << source << std::endl;
                return false;
            }
            
            int result = system(command.c_str());
            return result == 0;
            
        } catch (const std::exception& e) {
            std::cerr << "Error fetching data: " << e.what() << std::endl;
            return false;
        }
    }
};

void printUsage(const char* programName) {
    std::cout << "Usage: " << programName << " [OPTIONS] SYMBOL" << std::endl;
    std::cout << "Options:" << std::endl;
    std::cout << "  --test              Generate test data (default)" << std::endl;
    std::cout << "  --yahoo             Use Yahoo Finance via Python" << std::endl;
    std::cout << "  --alpha-vantage KEY Use Alpha Vantage API via Python" << std::endl;
    std::cout << "  --output-dir DIR    Output directory (default: data)" << std::endl;
    std::cout << "  --help              Show this help message" << std::endl;
    std::cout << std::endl;
    std::cout << "Examples:" << std::endl;
    std::cout << "  " << programName << " AAPL" << std::endl;
    std::cout << "  " << programName << " --yahoo AAPL" << std::endl;
    std::cout << "  " << programName << " --alpha-vantage YOUR_API_KEY MSFT" << std::endl;
    std::cout << "  " << programName << " --output-dir data/ GOOGL" << std::endl;
}

int main(int argc, char* argv[]) {
    // Initialize random seed
    srand(time(0));
    
    std::string symbol;
    std::string outputDir = "data";
    std::string source = "test";
    std::string apiKey;
    
    // Parse command line arguments
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        
        if (arg == "--help") {
            printUsage(argv[0]);
            return 0;
        } else if (arg == "--test") {
            source = "test";
        } else if (arg == "--yahoo") {
            source = "yahoo";
        } else if (arg == "--alpha-vantage") {
            source = "alpha-vantage";
            if (i + 1 < argc) {
                apiKey = argv[++i];
            } else {
                std::cerr << "Error: API key required for Alpha Vantage" << std::endl;
                return 1;
            }
        } else if (arg == "--output-dir") {
            if (i + 1 < argc) {
                outputDir = argv[++i];
            } else {
                std::cerr << "Error: Output directory required" << std::endl;
                return 1;
            }
        } else if (symbol.empty()) {
            symbol = arg;
        } else {
            std::cerr << "Error: Unknown argument: " << arg << std::endl;
            printUsage(argv[0]);
            return 1;
        }
    }
    
    if (symbol.empty()) {
        std::cerr << "Error: Symbol is required" << std::endl;
        printUsage(argv[0]);
        return 1;
    }
    
    bool success = false;
    
    if (source == "test") {
        success = TestDataGenerator::generateTestData(symbol, outputDir);
    } else {
        success = DataFetcher::fetchData(symbol, source, apiKey, outputDir);
    }
    
    if (success) {
        std::cout << "Data fetch completed successfully for " << symbol << std::endl;
        return 0;
    } else {
        std::cout << "Failed to fetch data for " << symbol << std::endl;
        return 1;
    }
}