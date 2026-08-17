local ComponentUtil = {}

function ComponentUtil.FindFirstComponentAncestor(sourceInstance: Instance, component)
	local ancestor = sourceInstance.Parent

	while ancestor do
		if ancestor:HasTag(component.Tag) then
			return component:FromInstance(ancestor)
		end

		ancestor = ancestor.Parent
	end

	return nil
end

return ComponentUtil