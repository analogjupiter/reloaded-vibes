const RV_MSG_INIT = 'ReloadedVibes::Init;';
const RV_MSG_TRIGGER = 'ReloadedVibes::Trigger;';
const RV_MSG_WARN = 'ReloadedVibes::Warn("';

let rvMsgCurrent = null;

function rvMsg(text, timeout = -1) {
    if (rvQuiet) {
        return;
    }

    if (rvMsgCurrent != null) {
        rvMsgCurrent.parentNode.removeChild(rvMsgCurrent);
    }
    let box = document.createElement('div');
    box.classList.add('reloaded-vibes');
    box.style.background = 'rgba(0, 0, 0, 0.89)';
    box.style.borderRadius = '5px';
    box.style.fontFamily = 'Ubuntu, sans-serif';
    box.style.margin = '0';
    box.style.minWidth = '20vw';
    box.style.padding = '1.25rem';
    box.style.position = 'fixed';
    box.style.right = '1.25rem';
    box.style.top = '1.25rem';
    let h = document.createElement('h2');
    box.appendChild(h);
    h.style.color = '#999';
    h.style.fontSize = '0.75rem';
    h.style.fontWeight = 'normal';
    h.style.margin = '0';
    h.style.padding = '0';
    h.style.textAlign = 'right';
    h.textContent = 'Reloaded Vibes';
    let p = document.createElement('p');
    box.appendChild(p);
    p.style.color = '#DDD';
    p.style.fontSize = '1.25rem';
    p.style.fontWeight = 'normal';
    p.style.margin = '0';
    p.style.padding = '0';
    p.textContent = text;
    document.body.appendChild(box);
    rvMsgCurrent = box;
    if (timeout > 0) {
        window.setTimeout(function () {
            rvMsgCurrent = null;
            box.parentNode.removeChild(box);
        }, (timeout * 1000));
    }
}

function attemptReconnect(currentConnectionAttempt, timeout) {
    window.setTimeout(function () {
        rvMsg('Attempting to reconnect…');
        window.setTimeout(function () {
            rvConnect(++currentConnectionAttempt);
        }, 1000);
    }, (timeout * 1000));
}

function rvConnect(connectionAttempt = 0) {
    let rv = new WebSocket(rvURL);
    let rvInitialized = false;

    rv.onopen = function () {
        rv.send('ReloadedVibes::Init;');
        rv.onclose = function () {
            rvMsg('Connection lost', 9);
            attemptReconnect(connectionAttempt, 10);
        };
    };

    rv.onerror = function (error) {
        if (connectionAttempt > 0) {
            if (connectionAttempt < 5) {
                attemptReconnect(connectionAttempt, 2);
                return;
            }
            rvMsg('Reconnect failed');
            return;
        }
        if (!rvInitialized)
        {
            rvMsg('Failed to establish connection');
            return;
        }
        rvMsg('WebSocket Error\nSee console for details.')
        console.log(error);
    };

    rv.onmessage = function (e) {
        if (e.data == RV_MSG_INIT) {
            rvInitialized = true;
            isReconnect = 0;
            rvMsg('Connected', 0.8);
            return;
        }
        else if (!rvInitialized) {
            rvMsg('Bad connection', 10);
            console.log(e.data);
            rv.onclose = null;
            rv.close();
            return;
        }

        if (e.data == RV_MSG_TRIGGER) {
            rvMsg('Reloading page…');
            rv.onclose = null;
            window.location.reload();
        }
        else if (e.data.startsWith(RV_MSG_WARN) && e.data.endsWith('");')) {
            rvMsg(e.data.substring(RV_MSG_WARN.length, (e.data.length - 2)))
        }
        else {
            rvMsg('Unhandled message\nSee console for details.', 10);
            console.log('Reloaded Vibes: Unhandled message ->' + e.data);
        }
    };
}

rvConnect();
