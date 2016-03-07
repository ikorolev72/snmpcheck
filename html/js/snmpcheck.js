function createCookie(name,value,hours) {
    if (hours) {
        var date = new Date();
        date.setTime(date.getTime()+(hours*60*60*1000));
        var expires = "; expires="+date.toGMTString();
    }
    else var expires = "";
    document.cookie = name+"="+value+expires+"; path=/";
}

function readCookie(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
        var c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
    }
    return null;
}

function eraseCookie(name) {
    createCookie(name,"",-1);
}


  function confirm_prompt( text,url ) {
     if (confirm( text )) {
      window.location = url ;
    }
  }
  
  
function isNumberInt(inputString) {
  return (!isNaN(parseInt(inputString))) ? true : false;
}

function cutLongText( field ) {

   var elem, size, text, ftext;
	elem = document.getElementById( field );
	text = elem.innerHTML;
	size = 100;
	ftext=elem.innerHTML;
	if (text.length > size) {
		text = text.slice(0, size);
	}
   	elem.innerHTML = text +'<a href="#" onclick="return alert( ftext );">...</a>';
}
//Now, calling functions

// createCookie('ppkcookie','testcookie',7);

//var x = readCookie('ppkcookie')
//if (x) {
//    [do something with x]
//}

function to_logout( ) {
	eraseCookie('id');
	eraseCookie('login');
	eraseCookie('name');
	eraseCookie('secret');
	return true;
}

function show_login_as( ) {
   var elem, text ;
	if( text=readCookie( 'name' ) ) {
		elem = document.getElementById( 'login_as' );
		elem.innerHTML = 'You are login as '+text+' [  <a href="" onclick="to_logout();"> logout </a> ]';		
	} else {
		elem = document.getElementById( 'login_as' );
		elem.innerHTML = '[  <a href="/cgi-bin/login.pl"> login </a> ]';				
	}
}