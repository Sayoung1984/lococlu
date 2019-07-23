// var rtname = "tmp/secrt.sitrep.testlab-sha1";
// function rtload(rtname) {
// 	let xhr = new XMLHttpRequest(),
// 		okStatus = document.location.protocol === "file:" ? 0 : 200;
// 	xhr.open('GET', rtname, false);
// 	xhr.overrideMimeType("text/html;charset=utf-8");//默认为utf-8
// 	xhr.send(null);
// 	return xhr.status === okStatus ? xhr.responseText : null;
// 	setTimeout("rtload(rtname)",500)
// };
// rtload(rtname);
// 
function readTextFile(file)
{
    // var x = document.getElementById("autoScroll").checked; //if autoscrool is checked
    // if(x==true){
    //  document.getElementById("result1").scrollTop = document.getElementById("textarea").scrollHeight; //autoscroll
    // }
// 
var filePath = "tmp/secrt.sitrep.testlab-sha1"

$.ajax({
dataType: "text",
success : function (data) {
		$("#result").load(filePath);
		}
});

}
setInterval(readTextFile, 1000);