local lsplens = {}
local config = require('lsp-lens.config')
local utils = require('lsp-lens.utils')

local lsp = vim.lsp

local methods = {
  'textDocument/implementation',
  'textDocument/definition',
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

local function requests_done(finished)
  for _, p in pairs(finished) do
    if not (p[1] == true and p[2] == true and p[3] == true) then
      return false
    end
  end
  return true
end

-- enum 
local SymbolKind = {
	Class = 5,
	Methods = 6,
	Interface = 11,
	Function = 12,
	Struct = 23,
}

local function get_functions(result)
  local ret = {}
  for _, v in pairs(result or {}) do
    if v.kind == SymbolKind.Function or v.kind == SymbolKind.Methods or v.kind == SymbolKind.Interface then
      table.insert(ret, {
        name = v.name,
        rangeStart = v.range.start,
        selectionRangeStart = v.selectionRange.start,
        selectionRangeEnd = v.selectionRange["end"],
      })
    elseif v.kind == SymbolKind.Class or v.kind == SymbolKind.Struct then
      ret = utils:merge_table(ret, get_functions(v.children))   -- Recursively find methods
    end
  end
  return ret
end

local function get_cur_document_functions(results)
  local ret = {}
  for _, res in pairs(results or {}) do
    ret = utils:merge_table(ret, get_functions(res.result))
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
    text = text .. "Definitions:" .. counting.definition .. " | "
  end
  if counting.implementation and counting.implementation > 0 then
    text = text .. "Implements:" .. counting.implementation .. " | "
  end
  if counting.reference and counting.reference > 0 then
    text = text .. "References:" .. counting.reference
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

local function delete_existing_lines(bufnr, ns_id)
  local existing_marks = vim.api.nvim_buf_get_extmarks(bufnr, ns_id, 0, -1, {})
  for _, v in pairs(existing_marks) do
    vim.api.nvim_buf_del_extmark(bufnr, ns_id, v[1])
  end
end

local function display_lines(bufnr, query_results)
  local ns_id = vim.api.nvim_create_namespace('lsp-lens')
  delete_existing_lines(bufnr, ns_id)
  for _, query in pairs(query_results or {}) do
    local virt_lines = {}
    local display_str = create_string(query.counting)
    if not (display_str == "") then
      local vline = { {string.rep(" ", query.rangeStart.character) .. display_str, "LspLens"} }
      table.insert(virt_lines, vline)
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, query.rangeStart.line, 0, {
        virt_lines = virt_lines,
        virt_lines_above = true
      })
    end
  end
end

local function do_request(symbols)
  if not (utils:is_buf_requesting(symbols.bufnr) == -1) then
    return
  else
    utils:set_buf_requesting(symbols.bufnr, 0)
  end

  local functions = symbols.document_functions_with_params
  local finished = {}

  for idx, function_info in pairs(functions or {}) do
    table.insert(finished, { false, false, false })

    local params = function_info.query_params
    local counting = {}

    if config.config.sections.implements == true and lsp_support_method(vim.api.nvim_get_current_buf(), methods[1]) then
      lsp.buf_request_all(symbols.bufnr, methods[1], params, function(implements)
        counting["implementation"] = result_count(implements)
        finished[idx][1] = true
      end)
    else
      finished[idx][1] = true
    end

    if config.config.sections.definition == true then
      lsp.buf_request_all(symbols.bufnr, methods[2], params, function(definition)
        counting["definition"] = result_count(definition)
        finished[idx][2] = true
      end)
    else
      finished[idx][2] = true
    end

    if config.config.sections.references == true then
      params.context = { includeDeclaration = config.config.include_declaration }
      lsp.buf_request_all(symbols.bufnr, methods[3], params, function(reference)
        counting["reference"] = result_count(reference)
        finished[idx][3] = true
      end)
    else
      finished[idx][3] = true
    end

    function_info["counting"] = counting
  end

  local timer = vim.loop.new_timer()
  timer:start(0, 500, vim.schedule_wrap(function()
    if requests_done(finished) then
      if timer ~= nil and timer.is_closing == false then
        timer:close()
      end
      display_lines(symbols.bufnr, functions)
      utils:set_buf_requesting(symbols.bufnr, 1)
    end
  end))
end

local function make_params(results)
  for _, query in pairs(results or {}) do
    local params = {
      position = {
        character = query.selectionRangeEnd.character,
        line = query.selectionRangeEnd.line
      },
      textDocument = lsp.util.make_text_document_params()
    }
    query.query_params = params
  end
  return results
end

function lsplens:lsp_lens_on()
  config.config.enable = true
  lsplens:procedure()
end

function lsplens:lsp_lens_off()
  config.config.enable = false
  delete_existing_lines(0, vim.api.nvim_create_namespace('lsp-lens'))
end

function lsplens:lsp_lens_toggle()
  if config.config.enable then
    lsplens:lsp_lens_off()
  else
    lsplens:lsp_lens_on()
  end
end

function lsplens:procedure()
  if config.config.enable == false then
    lsplens:lsp_lens_off()
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()

  -- Ignored Filetype
  if utils:table_find(config.config.ignore_filetype, vim.api.nvim_buf_get_option(bufnr, 'filetype')) then
    return
  end

  local method = 'textDocument/documentSymbol'
  if lsp_support_method(bufnr, method) then
    local params = { textDocument = lsp.util.make_text_document_params() }
    lsp.buf_request_all(bufnr, method, params, function(document_symbols)
      -- vim.pretty_print(lsp.buf_request_sync(0, "textDocument/codeLens", document_symbols, 1000))
      local symbols = {}
      symbols["bufnr"] = bufnr
      symbols["document_symbols"] = document_symbols
      symbols["document_functions"] = get_cur_document_functions(symbols.document_symbols)
      symbols["document_functions_with_params"] = make_params(symbols.document_functions)
      do_request(symbols)
    end)
  end
end

return lsplens
