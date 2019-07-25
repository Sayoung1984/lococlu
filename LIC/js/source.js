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
// // 
// function readTextFile(file)
// {
//     // var x = document.getElementById("autoScroll").checked; //if autoscrool is checked
//     // if(x==true){
//     //  document.getElementById("result1").scrollTop = document.getElementById("textarea").scrollHeight; //autoscroll
//     // }
// // 
// var filePath = "tmp/secrt.sitrep.testlab-sha1"
// 
// $.ajax({
// dataType: "text",
// success : function (data) {
// 		$("#result").load(filePath);
// 		}
// });
// 
// }
// setInterval(readTextFile, 1000);// function rttary(matrix) {  const rows = matrix.length, cols = matrix[0].length;  const grid = [];  for (let j = 0; j < cols; j++) {    grid[j] = Array(rows);  }  for (let i = 0; i < rows; i++) {    for (let j = 0; j < cols; j++) {      grid[j][i] = matrix[i][j];    }  }  return grid;}function wtjs(name) {	eval(readtxt(name));	// var lcc_load = rttary(lcc_load);	// var lcc_imgon = rttary(lcc_imgon);	// var lcc_ulsc = rttary(lcc_ulsc);	arrayToJson(lcc_load);	arrayToJson(lcc_imgon);	arrayToJson(lcc_ulsc);	console.log(lcc_load);	console.log(lcc_imgon);	console.log(lcc_ulsc);	setInterval(wtjs(name), 500);}var lccary_file = "/tmp/lccrep_ary"wtjs(lccary_file)