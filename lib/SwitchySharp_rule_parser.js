var wildcardToRegexp = function (pattern) {
	pattern = pattern.replace(/([\\\+\|\{\}\[\]\(\)\^\$\.\#])/g, "\\$1");
	pattern = pattern.replace(/\*/g, ".*");
	pattern = pattern.replace(/\?/g, ".");
	return pattern;
};

module.exports = function (data) {
	if (data == null || data.length < 2) {
		console.log("Too small AutoProxy rules file!");
		return;
	}
	if (data.substr(0, 10) != "[AutoProxy") {
		console.log("Invalid AutoProxy rules file!");
		return;
	}
	var lines = data.split(/[\r\n]+/);
	var rules = {
		wildcard: [],
		regexp: []
	};
	var patternType;
	for (var index = 0; index < lines.length; index++) {
		var line = lines[index].trim();

		if (line.length == 0 || line[0] == ';' || line[0] == '!' || line[0] == '[') // comment line
			continue;

		var exclude = false;
		if (line.substr(0, 2) == "@@") {
			exclude = true;
			line = line.substring(2);
		}

		if (line[0] == '/' && line[line.length - 1] == '/') { // regexp pattern
			patternType = "regexp";
			line = line.substring(1, line.length - 1);
		}
		else if (line.indexOf('^') > -1) {
			patternType = "regexp";
			line = wildcardToRegexp(line);
			line = line.replace(/\\\^/g, "(?:[^\\w\\-.%\\u0080-\\uFFFF]|$)");
		}
		else if (line.substr(0, 2) == "||") {
			patternType = "regexp";
			line = "^[\\w\\-]+:\\/+(?!\\/)(?:[^\\/]+\\.)?" + wildcardToRegexp(line.substring(2));
		}
		else if (line[0] == "|" || line[line.length - 1] == "|") {
			patternType = "regexp";
			line = wildcardToRegexp(line);
			line = line.replace(/^\\\|/, "^");
			line = line.replace(/\\\|$/, "$");
		}
		else {
			patternType = 'wildcard';
		}

		if (exclude)
			line = "!" + line;

		rules[patternType].push(line);
	}

	return rules;
};
