class DataHandler

	new: ( rawDataString ) =>
		-- (length-22)/4
		@tableize rawDataString
		@parsedData = {
			xPosition: { }
			yPosition: { }
			scale: { }
			rotation: { }
			width: rawDataString\match "Source Width\t([0-9]+)"
			height: rawDataString\match "Source Height\t([0-9]+)"
		}

	tableize: ( rawDataString ) =>
		@rawData = { }
		rawDataString\gsub "([^\n]+)", ( line ) ->
			table.insert @rawData, line

	parse: =>
		with @parsedData
			section = 0
			for _index, line in ipairs @parsedData
				unless line\match("^\t")
					if line == "Position" || line == "Scale" || line == "Rotation"
						section += 1
				else
					line\gsub "^\t([%d%.%-]+)\t([%d%.%-]+)\t", ( value1, value2 ) ->
						switch section
							when 1
								table.insert .xPosition, tonumber value1
								table.insert .yPosition, tonumber value2
							when 2
								table.insert .scale, tonumber value1
							when 3
								table.insert .rotation, -tonumber value1

	-- Arguments: fieldsToRemove is a table of the following format:
	-- { "xPosition", "yPosition", "scale", "rotation" }
	-- where each value is a field to be removed from the tracking data.
	stripFields: ( fieldsToRemove ) =>
		defaults = { xPosition: 0, yPosition: 0, scale: 100, rotation: 0 }
		for _index, field in ipairs fieldsToRemove
			for index, _value in ipairs @parsedData[field]
				@parsedData[field][index] = defaults[field]