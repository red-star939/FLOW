#include "DBManager.hpp"
#include <iostream>
#include <sstream>
#include <string>

#ifdef _WIN32
#include <windows.h>
#endif

int main(int argc, char* argv[]) {
#ifdef _WIN32
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCP(CP_UTF8);
#endif

    DB::DBManager db;

    // 기존 DB 파일 로드 (db/database.json 우선, 미존재시 database.json)
    db.load_from_file("db/database.json");

    // 인자가 전달된 단발성 CLI 명령어 처리
    if (argc > 1) {
        std::string cmd = argv[1];
        if (cmd == "show" || cmd == "list") {
            bool show_all = (argc >= 3 && std::string(argv[2]) == "all");
            db.print_db_status(show_all);
            return 0;
        } else if (cmd == "set" && argc >= 6 && std::string(argv[2]) == "formula") {
            int yr = std::stoi(argv[3]);
            std::string mid = argv[4];
            int m = std::stoi(argv[5]);
            std::string expr = (argc >= 7) ? argv[6] : "";
            if (db.set_formula(yr, mid, m, expr)) {
                db.save_to_file("db/database.json");
                double res = db.evaluate_expression(yr, m, expr);
                std::cout << "[DB Engine] MID 수식 설정 완료: " << yr << "년 -> MID: " << mid << " -> " << m << "월 -> [" << expr << "] = " << res << "\n";
            }
            return 0;
        } else if ((cmd == "remove" || cmd == "del") && argc >= 6 && std::string(argv[2]) == "formula") {
            int yr = std::stoi(argv[3]);
            std::string mid = argv[4];
            int m = std::stoi(argv[5]);
            if (db.remove_formula(yr, mid, m)) {
                db.save_to_file("db/database.json");
                std::cout << "[DB Engine] MID 수식 제거 완료: " << yr << "년 -> MID: " << mid << " -> " << m << "월\n";
            } else {
                std::cout << "[DB Engine Error] 수식 제거 실패 (항목 없음)\n";
            }
            return 0;
        } else if (cmd == "eval" && argc >= 4) {
            int yr = std::stoi(argv[2]);
            int m = std::stoi(argv[3]);
            std::string expr = (argc >= 5) ? argv[4] : "";
            double res = db.evaluate_expression(yr, m, expr);
            std::cout << "[DB Engine] 수식 계산 결과 (" << yr << "년 " << m << "월): " << expr << " = " << res << "\n";
            return 0;
        } else if (cmd == "add" && argc >= 7 && std::string(argv[2]) == "subid") {
            int yr = std::stoi(argv[3]);
            int m = std::stoi(argv[4]);
            std::string id = argv[5];
            std::string sub_id = argv[6];
            double val = (argc >= 8) ? std::stod(argv[7]) : 0.0;
            if (db.add_subid(yr, m, id, sub_id, val)) {
                db.save_to_file("db/database.json");
                std::cout << "[DB Engine] SubID 추가 성공: " << yr << "년 " << m << "월 -> ID: " << id
                          << " | SubID: " << sub_id << " = " << val << " (합계 자동 갱신 완료)\n";
            }
            return 0;
        } else if ((cmd == "remove" || cmd == "del") && argc >= 7 && std::string(argv[2]) == "subid") {
            int yr = std::stoi(argv[3]);
            int m = std::stoi(argv[4]);
            std::string id = argv[5];
            std::string sub_id = argv[6];
            if (db.remove_subid(yr, m, id, sub_id)) {
                db.save_to_file("db/database.json");
                std::cout << "[DB Engine] SubID 제거 성공: " << yr << "년 " << m << "월 -> ID: " << id
                          << " | SubID: " << sub_id << " (합계 자동 갱신 완료)\n";
            } else {
                std::cout << "[DB Engine Error] SubID 제거 실패 (항목 없음)\n";
            }
            return 0;
        } else if (cmd == "add" && argc >= 5 && std::string(argv[2]) == "mid") {
            int yr = std::stoi(argv[3]);
            std::string mid = argv[4];
            if (db.add_mid(yr, mid)) {
                db.save_to_file("db/database.json");
                std::cout << "[DB Engine] 년도 MID 추가 성공: " << yr << "년 -> MID: " << mid << "\n";
            }
            return 0;
        } else if ((cmd == "remove" || cmd == "del") && argc >= 5 && std::string(argv[2]) == "mid") {
            int yr = std::stoi(argv[3]);
            std::string mid = argv[4];
            if (db.remove_mid(yr, mid)) {
                db.save_to_file("db/database.json");
                std::cout << "[DB Engine] 년도 MID 제거 성공: " << yr << "년 -> MID: " << mid << "\n";
            } else {
                std::cout << "[DB Engine Error] MID 제거 실패 (항목 없음)\n";
            }
            return 0;
        } else if (cmd == "add" && argc >= 6 && std::string(argv[2]) == "id") {
            int yr = std::stoi(argv[3]);
            int m = std::stoi(argv[4]);
            std::string id = argv[5];
            if (db.add_id(yr, m, id)) {
                db.save_to_file("db/database.json");
                std::cout << "[DB Engine] ID 추가 성공: " << yr << "년 " << m << "월 -> ID: " << id << "\n";
            }
            return 0;
        } else if ((cmd == "remove" || cmd == "del") && argc >= 6 && std::string(argv[2]) == "id") {
            int yr = std::stoi(argv[3]);
            int m = std::stoi(argv[4]);
            std::string id = argv[5];
            if (db.remove_id(yr, m, id)) {
                db.save_to_file("db/database.json");
                std::cout << "[DB Engine] ID 제거 성공: " << yr << "년 " << m << "월 -> ID: " << id << "\n";
            } else {
                std::cout << "[DB Engine Error] ID 제거 실패 (항목 없음)\n";
            }
            return 0;
        } else if (cmd == "config" || cmd == "config_year" || cmd == "configyear") {
            int start_idx = (argc >= 3 && std::string(argv[2]) == "year") ? 3 : 2;
            if (argc > start_idx + 1) {
                int sy = std::stoi(argv[start_idx]);
                int ey = std::stoi(argv[start_idx + 1]);
                db.configure_year_range(sy, ey);
                db.save_to_file("db/database.json");
                std::cout << "[DB Engine] 년도 범위 설정 완료: " << sy << "년 ~ " << ey << "년 (자동 저장 완료)\n";
            } else {
                std::cout << "사용법: db_cmd config year <시작년도> <끝년도>\n";
            }
            return 0;
        }
    }

    // 대화형 REPL 모드
    std::cout << "=========================================================\n";
    std::cout << "            독립 JSON DB 엔진 관리 콘솔 (db/)           \n";
    std::cout << "=========================================================\n";
    std::cout << " 사용 가능한 명령어:\n";
    std::cout << "  - config year <시작> <끝>                           : 활성 년도 범위 설정 (예: config year 2000 2200)\n";
    std::cout << "  - add mid <년도> <MID명>                             : MID 생성 (예: add mid 2026 생활비용)\n";
    std::cout << "  - remove mid <년도> <MID명>                          : MID 제거 (예: remove mid 2026 생활비용)\n";
    std::cout << "  - add id <년> <월> <ID명>                            : 월별 ID 추가 (예: add id 2026 1 수입)\n";
    std::cout << "  - remove id <년> <월> <ID명>                         : 월별 ID 제거 (예: remove id 2026 1 수입)\n";
    std::cout << "  - add subid <년> <월> <ID> <SubID> <값>               : SubID 생성 및 값 추가 (예: add subid 2026 1 수입 월급 3000000)\n";
    std::cout << "  - remove subid <년> <월> <ID> <SubID>                : SubID 제거 (예: remove subid 2026 1 수입 월급)\n";
    std::cout << "  - set formula <년> <MID> <월> <수식>                : MID의 월별 수식 정의 (예: set formula 2026 생활비용 1 수입-지출)\n";
    std::cout << "  - remove formula <년> <MID> <월>                    : MID의 월별 수식 제거 (예: remove formula 2026 생활비용 1)\n";
    std::cout << "  - eval <년> <월> <수식>                             : 수식 평가 계산 (예: eval 2026 1 수입-지출)\n";
    std::cout << "  - show / list                                       : 전체 DB 상태 및 MID 수식 계산 결과 출력\n";
    std::cout << "  - show all                                          : 가려진 년도 포함 전체 DB 출력\n";
    std::cout << "  - save                                              : db/database.json 파일에 저장\n";
    std::cout << "  - load                                              : db/database.json 파일 로드\n";
    std::cout << "  - exit / quit                                       : 종료\n";
    std::cout << "=========================================================\n\n";

    db.print_db_status();

    std::string line;
    while (true) {
        std::cout << "DB Engine > ";
        if (!std::getline(std::cin, line)) break;

        line.erase(0, line.find_first_not_of(" \t\r\n"));
        line.erase(line.find_last_not_of(" \t\r\n") + 1);

        if (line.empty()) continue;
        if (line == "exit" || line == "quit") {
            std::cout << "DB 관리 콘솔을 종료합니다.\n";
            break;
        }
        if (line == "show" || line == "list") {
            db.print_db_status(false);
            continue;
        }
        if (line == "show all" || line == "list all") {
            db.print_db_status(true);
            continue;
        }
        if (line == "save") {
            if (db.save_to_file("db/database.json")) {
                std::cout << "[DB Engine] 'db/database.json' 저장 성공.\n";
            } else {
                std::cout << "[DB Engine Error] 저장 실패.\n";
            }
            continue;
        }
        if (line == "load") {
            if (db.load_from_file("db/database.json")) {
                std::cout << "[DB Engine] 'db/database.json' 로드 성공.\n";
                db.print_db_status();
            } else {
                std::cout << "[DB Engine Error] 로드 실패.\n";
            }
            continue;
        }

        // set formula <year> <mid> <month> <expr> 처리
        if (line.rfind("set formula ", 0) == 0 || line.rfind("set_formula ", 0) == 0) {
            std::string args = line.substr(12);
            args.erase(0, args.find_first_not_of(" \t"));
            std::stringstream ss(args);
            int yr = 0, m = 0;
            std::string mid, expr;
            if (ss >> yr >> mid >> m) {
                std::getline(ss, expr);
                expr.erase(0, expr.find_first_not_of(" \t"));
                if (db.set_formula(yr, mid, m, expr)) {
                    db.save_to_file("db/database.json");
                    double res = db.evaluate_expression(yr, m, expr);
                    std::cout << "[DB Engine] MID 수식 설정 완료: " << yr << "년 -> MID: " << mid << " -> " << m << "월 -> [" << expr << "] = " << res << "\n";
                }
            } else {
                std::cout << "[DB Engine Error] 사용법: set formula <년도> <MID명> <월> <수식구문>\n";
            }
            continue;
        }

        // remove formula <year> <mid> <month> 처리
        if (line.rfind("remove formula ", 0) == 0 || line.rfind("del formula ", 0) == 0 || line.rfind("remove_formula ", 0) == 0) {
            size_t prefix_len = (line.rfind("remove formula ", 0) == 0) ? 15 : 12;
            std::string args = line.substr(prefix_len);
            args.erase(0, args.find_first_not_of(" \t"));
            std::stringstream ss(args);
            int yr = 0, m = 0;
            std::string mid;
            if (ss >> yr >> mid >> m) {
                if (db.remove_formula(yr, mid, m)) {
                    db.save_to_file("db/database.json");
                    std::cout << "[DB Engine] MID 수식 제거 성공: " << yr << "년 -> MID: " << mid << " -> " << m << "월\n";
                } else {
                    std::cout << "[DB Engine Error] 수식 제거 실패 (해당 수식이 존재하지 않습니다.)\n";
                }
            } else {
                std::cout << "[DB Engine Error] 사용법: remove formula <년도> <MID명> <월>\n";
            }
            continue;
        }

        // eval <year> <month> <expr> 처리
        if (line.rfind("eval ", 0) == 0) {
            std::string args = line.substr(5);
            args.erase(0, args.find_first_not_of(" \t"));
            std::stringstream ss(args);
            int yr = 0, m = 0;
            std::string expr;
            if (ss >> yr >> m) {
                std::getline(ss, expr);
                expr.erase(0, expr.find_first_not_of(" \t"));
                double res = db.evaluate_expression(yr, m, expr);
                std::cout << "[DB Engine] 수식 계산 결과 (" << yr << "년 " << m << "월): " << expr << " = " << res << "\n";
            } else {
                std::cout << "[DB Engine Error] 사용법: eval <년도> <월> <수식구문>\n";
            }
            continue;
        }

        // add subid <year> <month> <id> <sub_id> <value> 처리
        if (line.rfind("add subid ", 0) == 0 || line.rfind("add_subid ", 0) == 0) {
            std::string args = line.substr(10);
            args.erase(0, args.find_first_not_of(" \t"));
            std::stringstream ss(args);
            int yr = 0, m = 0;
            std::string item_id, sub_id;
            double val = 0.0;
            if (ss >> yr >> m >> item_id >> sub_id >> val) {
                if (db.add_subid(yr, m, item_id, sub_id, val)) {
                    db.save_to_file("db/database.json");
                    std::cout << "[DB Engine] SubID 추가 성공: " << yr << "년 " << m << "월 -> ID: " << item_id
                              << " | SubID: " << sub_id << " = " << val << " (합계 자동 갱신 완료)\n";
                }
            } else {
                std::cout << "[DB Engine Error] 사용법: add subid <년도> <월> <ID명> <SubID명> <값>\n";
            }
            continue;
        }

        // remove subid <year> <month> <id> <sub_id> 처리
        if (line.rfind("remove subid ", 0) == 0 || line.rfind("del subid ", 0) == 0 || line.rfind("remove_subid ", 0) == 0) {
            size_t prefix_len = (line.rfind("remove subid ", 0) == 0) ? 13 : 10;
            std::string args = line.substr(prefix_len);
            args.erase(0, args.find_first_not_of(" \t"));
            std::stringstream ss(args);
            int yr = 0, m = 0;
            std::string item_id, sub_id;
            if (ss >> yr >> m >> item_id >> sub_id) {
                if (db.remove_subid(yr, m, item_id, sub_id)) {
                    db.save_to_file("db/database.json");
                    std::cout << "[DB Engine] SubID 제거 성공: " << yr << "년 " << m << "월 -> ID: " << item_id
                              << " | SubID: " << sub_id << " (합계 자동 갱신 완료)\n";
                } else {
                    std::cout << "[DB Engine Error] SubID 제거 실패 (해당 SubID가 존재하지 않습니다.)\n";
                }
            } else {
                std::cout << "[DB Engine Error] 사용법: remove subid <년도> <월> <ID명> <SubID명>\n";
            }
            continue;
        }

        // add mid <year> <mid> 처리
        if (line.rfind("add mid ", 0) == 0 || line.rfind("add_mid ", 0) == 0) {
            std::string args = line.substr(8);
            args.erase(0, args.find_first_not_of(" \t"));
            std::stringstream ss(args);
            int yr = 0;
            std::string mid;
            if (ss >> yr >> mid) {
                if (db.add_mid(yr, mid)) {
                    db.save_to_file("db/database.json");
                    std::cout << "[DB Engine] 년도 MID 추가 성공: " << yr << "년 -> MID: " << mid << "\n";
                }
            } else {
                std::cout << "[DB Engine Error] 사용법: add mid <년도> <MID명>\n";
            }
            continue;
        }

        // remove mid <year> <mid> 처리
        if (line.rfind("remove mid ", 0) == 0 || line.rfind("del mid ", 0) == 0 || line.rfind("remove_mid ", 0) == 0) {
            size_t prefix_len = (line.rfind("remove mid ", 0) == 0) ? 11 : 8;
            std::string args = line.substr(prefix_len);
            args.erase(0, args.find_first_not_of(" \t"));
            std::stringstream ss(args);
            int yr = 0;
            std::string mid;
            if (ss >> yr >> mid) {
                if (db.remove_mid(yr, mid)) {
                    db.save_to_file("db/database.json");
                    std::cout << "[DB Engine] 년도 MID 제거 성공: " << yr << "년 -> MID: " << mid << "\n";
                } else {
                    std::cout << "[DB Engine Error] MID 제거 실패 (해당 MID가 존재하지 않습니다.)\n";
                }
            } else {
                std::cout << "[DB Engine Error] 사용법: remove mid <년도> <MID명>\n";
            }
            continue;
        }

        // add id <year> <month> <id> 처리
        if (line.rfind("add id ", 0) == 0 || line.rfind("add_id ", 0) == 0) {
            std::string args = line.substr(7);
            args.erase(0, args.find_first_not_of(" \t"));
            std::stringstream ss(args);
            int yr = 0, m = 0;
            std::string item_id;
            if (ss >> yr >> m >> item_id) {
                if (db.add_id(yr, m, item_id)) {
                    db.save_to_file("db/database.json");
                    std::cout << "[DB Engine] ID 추가 성공: " << yr << "년 " << m << "월 -> ID: " << item_id << "\n";
                }
            } else {
                std::cout << "[DB Engine Error] 사용법: add id <년도> <월> <ID명>\n";
            }
            continue;
        }

        // remove id <year> <month> <id> 처리
        if (line.rfind("remove id ", 0) == 0 || line.rfind("del id ", 0) == 0 || line.rfind("remove_id ", 0) == 0) {
            size_t prefix_len = (line.rfind("remove id ", 0) == 0) ? 10 : 7;
            std::string args = line.substr(prefix_len);
            args.erase(0, args.find_first_not_of(" \t"));
            std::stringstream ss(args);
            int yr = 0, m = 0;
            std::string item_id;
            if (ss >> yr >> m >> item_id) {
                if (db.remove_id(yr, m, item_id)) {
                    db.save_to_file("db/database.json");
                    std::cout << "[DB Engine] ID 제거 성공: " << yr << "년 " << m << "월 -> ID: " << item_id << "\n";
                } else {
                    std::cout << "[DB Engine Error] ID 제거 실패 (해당 ID가 존재하지 않습니다.)\n";
                }
            } else {
                std::cout << "[DB Engine Error] 사용법: remove id <년도> <월> <ID명>\n";
            }
            continue;
        }

        // 년도 범위 설정 명령 처리
        if (line.rfind("config", 0) == 0 || line.rfind("config_year", 0) == 0 || line.rfind("set_range", 0) == 0) {
            std::string args = line;
            size_t first_space = args.find_first_of(" \t");
            if (first_space != std::string::npos) {
                args = args.substr(first_space);
            }
            args.erase(0, args.find_first_not_of(" \t"));
            if (args.rfind("year ", 0) == 0) {
                args = args.substr(5);
                args.erase(0, args.find_first_not_of(" \t"));
            }

            std::stringstream ss(args);
            int sy = 0, ey = 0;
            if (ss >> sy >> ey && sy > 1800 && ey < 3000) {
                db.configure_year_range(sy, ey);
                db.save_to_file("db/database.json");
                std::cout << "[DB Engine] 년도 범위 설정 완료: " << sy << "년 ~ " << ey << "년 (자동 저장 완료)\n";
            } else {
                std::cout << "[DB Engine Error] 올바른 년도 범위를 입력하세요. (예: config year 2000 2200)\n";
            }
            continue;
        }

        if (line.rfind("set year ", 0) == 0 || line.rfind("set_year ", 0) == 0) {
            std::string args = line.substr(9);
            args.erase(0, args.find_first_not_of(" \t"));
            std::stringstream ss(args);
            int yr = 0;
            if (ss >> yr && yr > 1800 && yr < 3000) {
                std::string desc;
                std::getline(ss, desc);
                desc.erase(0, desc.find_first_not_of(" \t"));
                db.set_year(yr, desc);
                db.save_to_file("db/database.json");
                std::cout << "[DB Engine] 년도 설정 및 저장 완료: " << yr << "년"
                          << (desc.empty() ? "" : " (" + desc + ")") << "\n";
            } else {
                std::cout << "[DB Engine Error] 유효한 년도를 입력하세요. (예: set year 2026)\n";
            }
            continue;
        }

        std::cout << "알 수 없는 명령어입니다. (set formula, remove formula, eval, add subid, remove subid, add id, remove id, add mid, remove mid, show, save, exit)\n";
    }

    return 0;
}
