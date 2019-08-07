function txt2op(name) {
	var run = "txt2op("+name+")";
	let xhr = new XMLHttpRequest();
		// okStatus = document.location.protocol === "file:" ? 0 : 200;
	xhr.open('GET', name);
	xhr.overrideMimeType("text/html; charset=utf-8"); //默认为utf-8
	// postMessage(xhr.responseText);
	xhr.onload = function(){
		self.postMessage(xhr.responseText.replace(/\\u0/g, ""));
		};
	xhr.send();
}

setInterval('txt2op("/tmp/lccrep_gen")', 500);
