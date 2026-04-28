local stringify = pandoc.utils.stringify

local function trim(text)
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function wrap_para(style_name, para)
  return pandoc.Div({ para }, pandoc.Attr("", {}, { { "custom-style", style_name } }))
end

local function para_from_markdown(text)
  local doc = pandoc.read(text, "markdown")
  if #doc.blocks > 0 and doc.blocks[1].t == "Para" then
    return doc.blocks[1]
  end
  return pandoc.Para({ pandoc.Str(text) })
end

local function image_only_para(block)
  return block.t == "Para" and #block.content == 1 and block.content[1].t == "Image"
end

local function figure_to_image_para(block)
  if block.t ~= "Figure" then
    return nil
  end

  local first = block.content and block.content[1] or nil
  if not first then
    return nil
  end

  if (first.t == "Para" or first.t == "Plain") and #first.content == 1 and first.content[1].t == "Image" then
    return pandoc.Para({ first.content[1] })
  end

  return nil
end

local function normalize_serial(num)
  return (num:gsub("%.", "-"))
end

local function ensure_sentence(text)
  if text == "" then
    return text
  end

  if text:match("[。！？%.%!%?]$") then
    return text
  end

  return text .. "。"
end

local function parse_caption(text, kind)
  -- Try with fullwidth colon first, then without.
  -- Cannot use ：? because Lua ? applies to a single byte, not a multi-byte char.
  local num, rest = text:match("^" .. kind .. "：%s*([0-9]+[%.%-][0-9]+)%s+(.+)$")
  if not num then
    num, rest = text:match("^" .. kind .. "%s*([0-9]+[%.%-][0-9]+)%s+(.+)$")
  end
  if not num then
    return nil
  end

  rest = trim(rest)
  local title, description = rest:match("^(.-)。(.*)$")
  if not title or title == "" then
    title = rest
    description = ""
  end

  return {
    number = normalize_serial(num),
    title = trim(title),
    description = trim(description or ""),
    label = kind .. normalize_serial(num) .. " " .. trim(title),
  }
end

local function build_figure_explanation(fig)
  if fig.description == "" then
    return nil
  end

  local description = ensure_sentence(fig.description)
  if description:match("^如图") then
    return para_from_markdown(description)
  end

  return para_from_markdown("如图" .. fig.number .. "所示，" .. description)
end

local function is_note_text(text)
  return text:match("^注：")
    or text:match("^注意：")
    or text:match("^关键注意：")
    or text:match("^⚠️%s*关键注意：")
end

local function transform_para(block)
  local text = trim(stringify(block))

  if image_only_para(block) then
    return { wrap_para("图", block) }
  end

  local fig = parse_caption(text, "图")
  if fig then
    return { wrap_para("图题", para_from_markdown(fig.label)) }
  end

  local tbl = parse_caption(text, "表")
  if tbl then
    return { wrap_para("表题1-1", para_from_markdown(tbl.label)) }
  end

  if is_note_text(text) then
    return { wrap_para("注意", para_from_markdown(text)) }
  end

  return { block }
end

function Blocks(blocks)
  local out = {}
  local i = 1

  while i <= #blocks do
    local block = blocks[i]
    local next_block = blocks[i + 1]
    local image_block = nil

    if image_only_para(block) then
      image_block = block
    else
      image_block = figure_to_image_para(block)
    end

    if image_block and next_block and next_block.t == "Para" then
      local fig = parse_caption(trim(stringify(next_block)), "图")
      if fig then
        local explanation = build_figure_explanation(fig)
        if explanation then
          table.insert(out, explanation)
        end
        table.insert(out, wrap_para("图", image_block))
        table.insert(out, wrap_para("图题", para_from_markdown(fig.label)))
        i = i + 2
      else
        table.insert(out, wrap_para("图", image_block))
        i = i + 1
      end
    else
      if image_block then
        table.insert(out, wrap_para("图", image_block))
      elseif block.t == "Para" then
        for _, transformed in ipairs(transform_para(block)) do
          table.insert(out, transformed)
        end
      else
        table.insert(out, block)
      end
      i = i + 1
    end
  end

  return out
end
