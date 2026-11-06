local uv = vim.uv or vim.loop
local root = vim.fn.getcwd()
local parser = assert(vim.env.LATEX_TEST_PARSER, "Set LATEX_TEST_PARSER to the built latex parser")
vim.treesitter.language.add("latex", { path = parser })
local function read(path)
	return table.concat(vim.fn.readfile(root .. "/" .. path), "\n")
end
local baseline = read("test/queries/upstream-highlights.scm")
local source = read("neovim/queries/latex/highlights.scm")
local original = vim.treesitter.query.parse("latex", baseline)
local candidate = vim.treesitter.query.parse("latex", source)
vim.treesitter.query.parse("latex", read("neovim/queries/latex/folds.scm"))
vim.treesitter.query.parse("latex", read("neovim/queries/latex/injections.scm"))

local function captures(query, text, tree, normalize)
	local found = {}
	for id, node, metadata in query:iter_captures(tree:root(), text) do
		local name = query.captures[id]
		local priority = tonumber(metadata.priority)
		-- These are the two intentional priority changes; all other captures,
		-- locations, multiplicities and metadata must agree with the baseline.
		if not (normalize and name == "punctuation.bracket" and priority == 110) then
			if normalize and priority == 90 then
				priority = nil
			end
			local row, col, last_row, last_col = node:range()
			found[#found + 1] =
				vim.inspect({ name, row, col, last_row, last_col, priority, metadata.conceal, metadata[id] })
		end
	end
	table.sort(found)
	return found
end

local samples = {
	"$\\left( x + y \\right)$",
	"$\\left\\{ \\frac{a}{b} \\right\\}$",
	"$\\left. x \\right|$",
	"$\\left[ \\left( x \\right) \\right]$",
	"\\[ \\left\\langle x \\middle| y \\right\\rangle \\]",
	"$\\left( x$",
	"$\\left( x \\right$",
	"$\\left x \\right)$",
	"$x \\right)$",
	"$\\left( \\right)$",
	"$\\left( x \\right]$",
	"\\begin{equation}\n\\label{eq:x}\n\\left( x \\right) & = \\alpha\n\\end{equation}",
	"\\includegraphics[width=0.8\\linewidth]{./Figures/design.pdf}",
}
for _, left in ipairs({ "\\left", "\\bigl", "\\Bigl", "\\biggl", "\\Biggl" }) do
	for _, right in ipairs({ "\\right", "\\bigr", "\\Bigr", "\\biggr", "\\Biggr" }) do
		for _, pair in ipairs({ { "(", ")" }, { "[", "]" }, { "\\{", "\\}" }, { ".", "|" } }) do
			samples[#samples + 1] = "$" .. left .. pair[1] .. " x + \\alpha " .. right .. pair[2] .. "$"
		end
	end
end
for _, path in ipairs(vim.fn.glob(root .. "/examples/*.tex", false, true)) do
	samples[#samples + 1] = table.concat(vim.fn.readfile(path), "\n")
end
for i, text in ipairs(samples) do
	local tree = vim.treesitter.get_string_parser(text, "latex"):parse()[1]
	assert(
		vim.deep_equal(captures(original, text, tree, true), captures(candidate, text, tree, true)),
		"Unexpected capture change in sample " .. i
	)
end

local function at(text, col)
	local tree = vim.treesitter.get_string_parser(text, "latex"):parse()[1]
	local found = {}
	for id, node, metadata in candidate:iter_captures(tree:root(), text) do
		local row, start, last_row, stop = node:range()
		if row == 0 and last_row == 0 and start <= col and col < stop then
			local name = candidate.captures[id]
			found[name] = math.max(found[name] or 0, tonumber(metadata.priority) or 100)
		end
	end
	return found
end
local text = "$x + \\alpha$"
local math = at(text, assert(text:find("\\alpha", 1, true)) - 1)
assert(math["markup.math"] == 90 and math["function"] == 100, vim.inspect(math))
local path = "\\includegraphics{Figures/diagram.pdf}"
for _, char in ipairs({ "{", "}" }) do
	local bracket = at(path, assert(path:find(char, 1, true)) - 1)
	assert(bracket["punctuation.bracket"] == 110 and bracket["string.special.path"] == 100, vim.inspect(bracket))
end
local inside = at(path, assert(path:find("Figures", 1, true)))
assert(inside["string.special.path"] == 100 and not inside["punctuation.bracket"])
print("PASS: " .. #samples .. " capture-equivalence cases, math/path priorities, folds and injections")

local function compile(text)
	local started = uv.hrtime()
	-- Exercise native compilation rather than Neovim's per-process query cache.
	assert(vim._ts_parse_query("latex", text))
	return (uv.hrtime() - started) / 1e6
end
local old, new = {}, {}
for i = 1, 7 do
	if i % 2 == 1 then
		old[i], new[i] = compile(baseline), compile(source)
	else
		new[i], old[i] = compile(source), compile(baseline)
	end
end
table.sort(old)
table.sort(new)
print(string.format("Query compile median (7 interleaved samples): upstream %.2f ms; fork %.2f ms", old[4], new[4]))
