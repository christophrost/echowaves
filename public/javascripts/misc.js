function pageScroll() {
  window.scrollBy(0,50000); // horizontal and vertical scroll increments
}

  // try to focus an input field, if we can find it
function focusInput(inputId) {
  if ($(inputId)) {
    $(inputId).focus();
  }
}

function working_begin() {
  $('working').appear({ duration: 0.3 });
}
function working_end() {
  $('working').fade({ duration: 0.3 });
}

function handle_new_messages() {
  var new_last_msg_num = find_last_message_number();
  if (last_message_number < new_last_msg_num) { // shortcut if nothing's changed
    var newMessages = identify_new_messages(last_message_number + 1, new_last_msg_num);
    last_message_number = new_last_msg_num;
    WindowManager.moreMessagesHaveArrived(newMessages)
  }
  suspend_polling = false; // in case we had shut it off for some reason
  working_end();
}

function find_last_message_number() {
  var last_msg = $('messages').childElements().last();
  var num = parseInt(last_msg.id.sub("message",""));
  return num;
}

function identify_new_messages(first, last) {
  var newMessages = new Array();
  for (var i = first; i <= last; i++) {
    if ($("message"+i)) { // some might be in other conversations
      newMessages.push(i);
    }
  }
  return newMessages;
}