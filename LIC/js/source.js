function txt2op(name) {
	var run = "txt2op("+name+")";
	let xhr = new XMLHttpRequest();
		// okStatus = document.location.protocol === "file:" ? 0 : 200;
	xhr.open('GET', name);
	xhr.overrideMimeType("text/html; charset=utf-8"); //默认为utf-8
	// postMessage(xhr.responseText);
	xhr.onload = function(){
		self.postMessage(xhr.responseText);
		};
	xhr.send();
}

var lccinfo_file = "/tmp/lccinfo";
var lccary_file = "/tmp/lccrep_ary";
setInterval('txt2op(lccary_file)', 500);
setTimeout('txt2op(lccinfo_file)', 500);
