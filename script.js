//# javascript from https://github.com/Appsilon/shiny.collections/blob/master/inst/examples/www/script.js

jQuery(document).ready(function(){
  jQuery('#msg_text').keypress(function(evt){
    if (evt.keyCode == 13){
      // Enter, simulate clicking send
      jQuery('#msg_button').click();
    }
  });
})


// Scrolling down when new messages are received
var oldContent = null;
window.setInterval(function() {
  var elem = document.getElementById('chat-container');
  if (oldContent != elem.innerHTML){
    scrollToBottom();
  }
  oldContent = elem.innerHTML;
}, 10);

function scrollToBottom(){
  var elem = document.getElementById('chat-container');
  elem.scrollTop = elem.scrollHeight;
}