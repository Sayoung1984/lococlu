// https: //developer.mozilla.org/zh-CN/docs/Web/API/Web_Workers_API/Using_web_workers

function txtop(name) {
	let xhr = new XMLHttpRequest(),
		// okStatus = document.location.protocol === "file:" ? 0 : 200;
	xhr.open('GET', name, false);
	xhr.overrideMimeType("text/html; charset=utf-8"); //默认为utf-8
	xhr.send(null);
	// console.log(typeof xhr.responseText);
	// console.log(xhr.responseText);
	// return xhr.status === okStatus ? xhr.responseText : null;
	// return xhr.responseText;
}


var lccinfo_file = "/tmp/lccinfo";
var lccary_file = "/tmp/lccrep_ary";
setInterval('txtop(lccary_file)', 500);
setInterval('txtop(lccinfo_file)', 500);
