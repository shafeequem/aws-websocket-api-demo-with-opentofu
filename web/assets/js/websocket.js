function start(websocketServerLocation) {
    ws = new WebSocket(websocketServerLocation);
    ws.onmessage = function (evt) {
        //alert(event.data); 
        $('#messages').append('<h2>' + event.data + '</h2>');
    };
    ws.onopen = function () {
        console.log('WebSocket connection opened:', event);
    };
    ws.onclose = function () {
        console.log('WebSocket connection closed:', event);
        // Try to reconnect in 5 seconds
        setTimeout(function () { start(websocketServerLocation) }, 5000);
    };
}

$("#username_submit").click(function () {
    var username = $('#username').val();
    if (username) {
        $("#username_submit").attr("disabled", true);
        $("#username").attr("disabled", true);
        //var websocketServerLocation = "wss://7ytbgidipk.execute-api.us-east-1.amazonaws.com/develop?key=xcvsdf&user=";
        //var websocketServerLocation = "SOCKET_ADDRESS?key=xcvsdf&user=";
        var websocketServerUrl = websocketServerLocation + username;
        start(websocketServerUrl);
    }
});

// const socket = new WebSocket('wss://irkzageyzg.execute-api.us-east-1.amazonaws.com/develop?key=xcvsdf&user=shafeeque');
// socket.addEventListener('open', (event) => {
//   console.log('WebSocket connection opened:', event);
// });

// socket.addEventListener('message', (event) => {
//   // Handle the received notification, e.g., display it to the user
//   alert(`Received Notification: ${event.data}`);
// });

// socket.addEventListener('close', (event) => {
//   console.log('WebSocket connection closed:', event);
// });