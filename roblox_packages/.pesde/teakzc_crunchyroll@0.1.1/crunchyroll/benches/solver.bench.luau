local ReplicatedStorage = game:GetService("ReplicatedStorage")

local create_bench = require(ReplicatedStorage.benches.create_bench)
local create_entry = require(ReplicatedStorage.benches.create_entry)

type Crunchyroll = create_entry.Crunchyroll

local entries = {
	latest = create_entry(require(ReplicatedStorage.crunchyroll:Clone()) :: Crunchyroll),
}

for _, mirror in ReplicatedStorage.benches.mirrors:GetChildren() do
	local label = mirror.Name
	assert(entries[label] == nil, `duplicate bench entry "{label}"`)

	local module = assert(mirror:FindFirstChild("crunchyroll"))
	local library = (require)(module:Clone()) :: Crunchyroll

	entries[label] = create_entry(library)
end

return create_bench(function() end, entries)
