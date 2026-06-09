-- Auto-number §N cross-references.
-- Authors link to a section with the literal text "§":  [§](#section-id)
-- This rewrites the link text to "§N", where N is the target section's
-- position among level-1 headings -- matching the CSS nav/section counters.
-- Links with any other text are left untouched, so normal links still work.

local stringify = pandoc.utils.stringify

function Pandoc(doc)
	local num = {}
	local n = 0
	doc.blocks:walk({
		Header = function(h)
			if h.level == 1 and h.identifier ~= "" then
				n = n + 1
				num[h.identifier] = n
			end
		end,
	})
	return doc:walk({
		Link = function(l)
			local id = l.target:match("^#(.+)$")
			if id and num[id] then
				local txt = stringify(l.content)
				if txt == "" or txt == "§" then
					return pandoc.Link({ pandoc.Str("§" .. num[id]) }, l.target, l.title)
				end
			end
			return nil
		end,
	})
end
