#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <bcrypt.h>
#include <filesystem>
#include <fstream>
#include <memory>
#include <regex>
#include <stdexcept>
#include <string>
#include <vector>

#pragma comment(lib, "bcrypt.lib")
namespace fs = std::filesystem;

namespace {
int module_marker;
struct Job {
    HMODULE module;
    fs::path root;
    std::string operation;
    std::wstring id;
    std::wstring argument;
};

void require(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}

void reject_links(fs::path path) {
    for (;;) {
        DWORD flags = GetFileAttributesW(path.c_str());
        if (flags != INVALID_FILE_ATTRIBUTES) {
            require(!(flags & FILE_ATTRIBUTE_REPARSE_POINT), "Linked path rejected");
        } else {
            DWORD error = GetLastError();
            require(error == ERROR_FILE_NOT_FOUND || error == ERROR_PATH_NOT_FOUND,
                    "Could not inspect path");
        }
        auto parent = path.parent_path();
        if (parent.empty() || parent == path) return;
        path = parent;
    }
}

std::string quote(const std::string& value) {
    std::string result = "\"";
    for (unsigned char c : value) {
        if (c == '"' || c == '\\') {
            result += '\\';
            result += static_cast<char>(c);
        } else if (c < 32) {
            const char* hex = "0123456789abcdef";
            result += "\\u00";
            result += hex[c >> 4];
            result += hex[c & 15];
        } else {
            result += static_cast<char>(c);
        }
    }
    return result + '"';
}

std::string sha256(const fs::path& path) {
    std::ifstream input(path, std::ios::binary);
    require(input.is_open(), "Game executable unavailable");
    BCRYPT_HASH_HANDLE hash = nullptr;
    require(BCryptCreateHash(BCRYPT_SHA256_ALG_HANDLE, &hash, nullptr, 0, nullptr, 0, 0) == 0,
            "Could not initialize SHA-256");
    struct HashGuard {
        BCRYPT_HASH_HANDLE handle;
        ~HashGuard() { BCryptDestroyHash(handle); }
    } guard{hash};
    std::vector<unsigned char> buffer(1024 * 1024);
    while (input.read(reinterpret_cast<char*>(buffer.data()), buffer.size()) || input.gcount()) {
        require(BCryptHashData(hash, buffer.data(), static_cast<ULONG>(input.gcount()), 0) == 0,
                "Could not hash game executable");
    }
    require(input.eof() && !input.bad(), "Could not read game executable");
    unsigned char digest[32];
    require(BCryptFinishHash(hash, digest, sizeof(digest), 0) == 0, "Could not finish SHA-256");
    const char* hex = "0123456789abcdef";
    std::string result;
    for (unsigned char b : digest) {
        result += hex[b >> 4];
        result += hex[b & 15];
    }
    return result;
}

std::string identify(const fs::path& root) {
    auto win64 = root.parent_path().parent_path().parent_path();
    auto steamapps = win64;
    for (int i = 0; i < 5; ++i) steamapps = steamapps.parent_path();
    std::string build, branch = "unknown", game = "Bladesong";
    const auto steam_install = steamapps / L"common/Bladesong/Bladesong/Binaries/Win64";
    if (_wcsicmp(win64.generic_wstring().c_str(), steam_install.generic_wstring().c_str()) == 0) {
        std::ifstream manifest(steamapps / L"appmanifest_2305640.acf", std::ios::binary);
        if (manifest) {
            std::string content(1024 * 1024 + 1, '\0');
            manifest.read(content.data(), content.size());
            content.resize(static_cast<size_t>(manifest.gcount()));
            require(content.size() <= 1024 * 1024 && !manifest.bad(), "Invalid Steam manifest size");
            std::smatch match;
            if (std::regex_search(content, match, std::regex("\"buildid\"\\s+\"([0-9]+)\""))) {
                build = match[1];
                game = "Steam build " + build;
            }
            if (std::regex_search(content, match, std::regex("\"BetaKey\"\\s+\"([^\"\\r\\n]+)\""))) {
                if (match[1] == "public") branch = "main";
                if (match[1] == "bleedingedge") branch = "bleedingedge";
            }
        }
    }
    std::string result = "{\"sha256\":" + quote(sha256(win64 / L"Bladesong-Win64-Shipping.exe"))
        + ",\"game\":" + quote(game) + ",\"branch\":" + quote(branch);
    if (!build.empty()) result += ",\"buildid\":" + quote(build);
    return result + '}';
}

std::string list_saves(const std::wstring& argument) {
    auto source = fs::absolute(argument).lexically_normal();
    require(source.filename() == L"SaveGames", "Expected SaveGames directory");
    reject_links(source);
    std::string result = "[";
    size_t count = 0, directories = 1;
    for (const auto& entry : fs::recursive_directory_iterator(source)) {
        DWORD flags = GetFileAttributesW(entry.path().c_str());
        require(flags != INVALID_FILE_ATTRIBUTES && !(flags & FILE_ATTRIBUTE_REPARSE_POINT),
                "Save path unavailable or linked");
        if (flags & FILE_ATTRIBUTE_DIRECTORY) {
            require(++directories <= 6000, "Save directory count limit");
        } else if (_wcsicmp(entry.path().extension().c_str(), L".sav") == 0) {
            require(count < 6000 && result.size() < 16 * 1024 * 1024, "Save file list limit");
            if (count++) result += ',';
            result += "{\"source\":" + quote(entry.path().generic_u8string()) + '}';
        }
    }
    return result + ']';
}

void write_result(const fs::path& path, const std::string& content) {
    auto temp = path;
    temp += L".tmp";
    reject_links(path);
    HANDLE file = CreateFileW(temp.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, nullptr);
    require(file != INVALID_HANDLE_VALUE, "Could not create service result");
    DWORD written = 0;
    bool ok = WriteFile(file, content.data(), static_cast<DWORD>(content.size()), &written, nullptr)
        && written == content.size();
    CloseHandle(file);
    if (!ok || !MoveFileExW(temp.c_str(), path.c_str(), MOVEFILE_REPLACE_EXISTING)) {
        DeleteFileW(temp.c_str());
        throw std::runtime_error("Could not save service result");
    }
}

void run_job(const Job& job) {
    auto result_path = job.root / (job.id + L".result.json");
    std::string result;
    try {
        reject_links(job.root);
        if (job.operation == "identify") {
            result = "{\"status\":\"complete\",\"identity\":" + identify(job.root) + '}';
        } else if (job.operation == "list-saves") {
            result = "{\"status\":\"complete\",\"files\":" + list_saves(job.argument) + '}';
        } else {
            auto input = job.root / (job.id + L".settings.json");
            auto target = job.root / L"Data/settings.json";
            reject_links(input);
            reject_links(target);
            require(fs::file_size(input) <= 1048576, "Settings size limit");
            fs::create_directory(target.parent_path());
            require(MoveFileExW(input.c_str(), target.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH),
                    "Could not replace settings");
            result = "{\"status\":\"complete\"}";
        }
    } catch (const std::exception&) {
        // Exception messages from filesystem APIs can contain non-UTF-8 local paths.
        result = "{\"status\":\"failed\",\"error\":\"Framework local service could not complete its operation\"}";
    }
    write_result(result_path, result);
}

DWORD WINAPI run_thread(void* context) {
    auto job = std::unique_ptr<Job>(static_cast<Job*>(context));
    HMODULE module = job->module;
    try { run_job(*job); } catch (...) {}
    job.reset();
    FreeLibraryAndExitThread(module, 0);
}

bool start(const char* wire, unsigned size) {
    std::string request(wire, size);
    auto first = request.find('\0');
    auto second = first == std::string::npos ? first : request.find('\0', first + 1);
    if (second == std::string::npos) return false;
    auto operation = request.substr(0, first);
    if (operation != "identify" && operation != "list-saves" && operation != "settings") return false;
    auto id = request.substr(first + 1, second - first - 1);
    if (!std::regex_match(id, std::regex("job_[A-Za-z0-9_-]{1,80}"))) return false;

    auto job = std::make_unique<Job>();
    job->operation = operation;
    job->id.assign(id.begin(), id.end());
    const char* argument = request.c_str() + second + 1;
    if (request.find('\0', second + 1) != std::string::npos) return false;
    int length = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, argument, -1, nullptr, 0);
    if (!length) return false;
    job->argument.resize(length);
    if (!MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, argument, -1, job->argument.data(), length)) return false;
    job->argument.pop_back();

    if (!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, reinterpret_cast<LPCWSTR>(&module_marker),
                            &job->module)) return false;
    wchar_t path[32768];
    DWORD count = GetModuleFileNameW(job->module, path, 32768);
    if (count && count < 32768) {
        try {
            auto scripts = fs::path(path).parent_path();
            job->root = scripts.parent_path();
            require(scripts.filename() == L"Scripts" && job->root.filename() == L"BladesongModFramework",
                    "Invalid service directory");
            Job* raw = job.release();
            HANDLE thread = CreateThread(nullptr, 0, run_thread, raw, 0, nullptr);
            if (thread) {
                CloseHandle(thread);
                return true;
            }
            job.reset(raw);
        } catch (...) {}
    }
    FreeLibrary(job->module);
    return false;
}

// UE4SS and the fixture runner use the same Lua 5.4 integer TValue layout.
using Word = unsigned long long;
bool integer(void* state, unsigned index, Word& value) {
    auto call = *reinterpret_cast<Word*>(static_cast<char*>(state) + 0x20);
    auto frame = *reinterpret_cast<Word*>(call);
    auto slot = frame + 16ull * index;
    if (*reinterpret_cast<unsigned char*>(slot + 8) != 3) return false;
    value = *reinterpret_cast<Word*>(slot);
    return true;
}

int push_result(void* state, bool value) {
    auto& top = *reinterpret_cast<Word*>(static_cast<char*>(state) + 0x10);
    *reinterpret_cast<Word*>(top) = value ? 1 : 0;
    *reinterpret_cast<unsigned char*>(top + 8) = 3;
    top += 16;
    return 1;
}

bool checked_start(const char* wire, unsigned size) noexcept {
    try { return start(wire, size); } catch (...) { return false; }
}
}

extern "C" __declspec(dllexport) int bmf_local_service(void* state) {
    __try {
        Word size;
        char wire[16000];
        if (!integer(state, 1, size) || size < 4 || size > sizeof(wire)) return push_result(state, false);
        auto top = *reinterpret_cast<Word*>(static_cast<char*>(state) + 0x10);
        auto call = *reinterpret_cast<Word*>(static_cast<char*>(state) + 0x20);
        auto frame = *reinterpret_cast<Word*>(call);
        if (top < frame || (top - frame) / 16 != size + 2) return push_result(state, false);
        for (unsigned index = 0; index < size; ++index) {
            Word value;
            if (!integer(state, index + 2, value) || value > 255) return push_result(state, false);
            wire[index] = static_cast<char>(value);
        }
        return push_result(state, checked_start(wire, static_cast<unsigned>(size)));
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        return 0;
    }
}
