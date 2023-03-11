local utils = {}
local config = require('lsp_lens.config')

local lsp = vim.lsp

local methods = {
  'textDocument/definition',
  'textDocument/implementation',
  'textDocument/references',
}

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
    for _, v in pairs(res.result or {}) do
      -- TODO: detect Method(6) of Struct(23) and Class(5)
      if v.kind == 12 then
        table.insert(ret, { name = v.name, rangeStart = v.range.start, selectionRangeStart = v.selectionRange.start })
      end
    end
  end
  return ret
end

local function lsp_support_method(buf, method)
  for _, client in pairs(lsp.get_active_clients({ bufnr = buf })) do
    if client.supports_method(method) then
      return true
    end
  end
  return false
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

local function generate_function_id(function_info)
  return function_info.name ..
    "uri=" .. function_info.query_params.textDocument.uri ..
    "character=" .. function_info.selectionRangeStart.character ..
    "line=" .. function_info.selectionRangeStart.line
end

local function requests_done(finished)
  for _, p in pairs(finished) do
    if not (p[1] == true and p[2] == true and p[3] == true) then
      return false
    end
  end
  return true
end

local function delete_existing_lines(ns_id)
  local existing_marks = vim.api.nvim_buf_get_extmarks(0, ns_id, 0, -1, {})
  for _, v in pairs(existing_marks) do
    vim.api.nvim_buf_del_extmark(0, ns_id, v[1])
  end
end

local function display_lines(query_results)
  local ns_id = vim.api.nvim_create_namespace('lsp-lens')
  delete_existing_lines(ns_id)
  for _, query in pairs(query_results) do
    local virt_lines = {}
    local vline = { {string.rep(" ", query.rangeStart.character) .. create_string(query.counting), "COMMENT"} }
    table.insert(virt_lines, vline)
    vim.api.nvim_buf_set_extmark(0, ns_id, query.rangeStart.line-1, 0, {virt_lines = virt_lines})
  end
end

local function do_request(functions)
  local finished = {}

  for idx, function_info in pairs(functions) do
    table.insert(finished, { false, false, false })

    local params = function_info.query_params
    local counting = {}

    if lsp_support_method(vim.api.nvim_get_current_buf(), methods[2]) then
      lsp.buf_request_all(0, methods[2], params, function(implements)
        counting["implementation"] = result_count(implements)
        finished[idx][1] = true
      end)
    else
      finished[idx][1] = true
    end

    lsp.buf_request_all(0, methods[1], params, function(definition)
      counting["definition"] = result_count(definition)
      finished[idx][2] = true
    end)

    params.context = { includeDeclaration = config.config.include_declaration }
    lsp.buf_request_all(0, methods[3], params, function(references)
      counting["references"] = result_count(references)
      finished[idx][3] = true
    end)

    function_info["counting"] = counting
  end

  local timer = vim.loop.new_timer()
  -- local start_request = vim.loop.now()
  timer:start(0, 100, vim.schedule_wrap(function()
    if requests_done(finished) then
      timer:stop()
      timer:close()
      display_lines(functions)
    end
  end))
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

function utils:nvim_lens_off()
  delete_existing_lines(vim.api.nvim_create_namespace('lsp-lens'))
end

function utils:procedure()
  local method = 'textDocument/documentSymbol'
  local params = { textDocument = lsp.util.make_text_document_params() }

  if lsp_support_method(vim.api.nvim_get_current_buf(), method) then
    lsp.buf_request_all(0, method, params, function(document_symbols)
      local document_functions = get_cur_document_functions(document_symbols)
      -- vim.pretty_print(document_functions)
      local document_functions_with_params = make_params(document_functions)
      -- vim.pretty_print(document_functions_with_params)
      do_request(document_functions_with_params)
    end)
  end
end

return utils
