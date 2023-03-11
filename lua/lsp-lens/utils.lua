local M = {}

function M:merge_table(tbl1, tbl2)
  local ret = {}
  for _, item in pairs(tbl1 or {}) do
    table.insert(ret, item)
  end
  for _, item in pairs(tbl2 or {}) do
    table.insert(ret, item)
  end
  return ret
end

return M

