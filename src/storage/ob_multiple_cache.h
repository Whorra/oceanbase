//
// Created by lx on 2021/12/12.
//

#ifndef OCEANBASE_CE_OB_MULTIPLE_CACHE_H
#define OCEANBASE_CE_OB_MULTIPLE_CACHE_H

#include <unordered_map>

namespace oceanbase {
namespace storage {
extern std::unordered_map<uint64_t, std::unordered_map<int32_t, ObNewRow*>> table_rows_cache;
  // extern std::unordered_map<uint64_t, std::unordered_map<int, common::ObNewRow*>> table_rows_cache;

}  // end namespace memtable
}  // end namespace oceanbase


#endif  // OCEANBASE_CE_OB_MULTIPLE_CACHE_H
