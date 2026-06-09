local files = require("_NickCore/Files")

for _, path in ipairs(files) do
    if path:find("_NickCore\\Installed\\", 1, true) then
		local name = path:match("([^\\]+)%.json$") .. "_installed"
        _G[name] = true
    end
end