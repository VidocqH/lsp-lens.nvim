local utils = {}

local lsp = vim.lsp

local methods = {
  'textDocument/definition',
  'textDocument/implementation',
  'textDocument/references',
}

local function request_done()
  local done = true
  ---@diagnostic disable-next-line: param-type-mismatch
  for _, method in pairs(methods()) do
    if not self.request_status[method] then
      done = false
      break
    end
  end
  return done
end

local function result_count(results)
  local ret = 0
  for _, res in pairs(results or {}) do
    for _, _ in pairs(res.result or {}) do
      ret = ret + 1
    end
  end
  return ret
end

local function get_cur_document_functions(results)
  local ret = {}
  for _, res in pairs(results or {}) do
    for _, v in pairs(res.result) do
      -- TODO: detect Method(6) of Struct(23) and Class(5)
      if v.kind == 12 then
        table.insert(ret, { name = v.name, rangeStart = v.range.start, selectionRangeStart = v.selectionRange.start })
      end
    end
  end
  return ret
end

local function supports_implement(buf)
  for _, client in pairs(lsp.get_active_clients({ bufnr = buf })) do
    if client.supports_method('textDocument/implementation') then
      return true
    end
  end
  return false
end

local function do_request(params)
  local counting = {}
  if supports_implement(vim.api.nvim_get_current_buf()) then
    local implements = lsp.buf_request_sync(0, methods[2], params, 10000)
    counting["implementation"] = result_count(implements)
  end
  local definitions = lsp.buf_request_sync(0, methods[1], params, 10000)
  counting["definition"] = result_count(definitions)
  -- vim.pretty_print(definitions)
  params.context = { includeDeclaration = true }
  local references = lsp.buf_request_sync(0, methods[3], params, 10000)
  -- vim.pretty_print(references)
  counting["references"] = result_count(references)
  return counting
end

local function make_params(results)
  for _, query in pairs(results) do
    local params = {
      position = {
        character = query.selectionRangeStart.character,
        line = query.selectionRangeStart.line
      },
      textDocument = lsp.util.make_text_document_params()
    }
    query.query_params = params
  end
  return results
end

local function get_document_symbol()
  local params = { textDocument = lsp.util.make_text_document_params() }
  local results = lsp.buf_request_sync(0, 'textDocument/documentSymbol', params, 10000)
  return results
end

local function do_functions_request(functions) 
  for _, v in pairs(functions) do
    v.counting = do_request(v.query_params)
  end
  return functions
end

local function create_string(counting)
  local text = ""
  if counting.definition and counting.definition > 0 then
    text = text .. "Definition:" .. counting.definition .. " | "
  end
  if counting.implementation and counting.implementation > 0 then
    text = text .. "Implementation:" .. counting.implementation .. " | "
  end
  if counting.references and counting.references > 0 then
    text = text .. "References:" .. counting.references
  end
  if text:sub(-3) == ' | ' then
    text = text:sub(1, -4)
  end
  return text
end

local function delete_existing_lines(ns_id)
  local existing_marks = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, {})
  for _, v in pairs(existing_marks) do
    vim.api.nvim_buf_del_extmark(0, ns_id, v[1])
  end
end

function utils:nvim_lens_off()
  delete_existing_lines(vim.api.nvim_create_namespace('lens'))
end

local function display_lines(query_results)
  local ns_id = vim.api.nvim_create_namespace('lens')
  delete_existing_lines(ns_id)
  for _, query in pairs(query_results) do
    local virt_lines = {}
    local vline = { {string.rep(" ", query.rangeStart.character) .. create_string(query.counting), "COMMENT"} }
    table.insert(virt_lines, vline)
    vim.api.nvim_buf_set_extmark(0, ns_id, query.rangeStart.line-1, 0, {virt_lines = virt_lines})
  end
end

function utils:procedure()
  local document_symbols = get_document_symbol()
  local document_functions = get_cur_document_functions(document_symbols)
  -- vim.pretty_print(document_functions)
  local document_functions_with_params = make_params(document_functions)
  -- vim.pretty_print(document_functions_with_params)
  local results = do_functions_request(document_functions_with_params)
  -- vim.pretty_print(results)
  display_lines(results)
end

return utils
