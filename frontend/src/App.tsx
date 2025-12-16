import {
  useEffect,
  useRef,
  useState,
  type FormEvent,
  type KeyboardEvent,
} from "react";

interface Message {
  id: string;
  sender?: string;
  text: string;
  ts: string;
}

const URL = import.meta.env.VITE_WS_CLIENT_URL;

function App() {
  const [userName, setUserName] = useState("");
  const [showNamePopup, setShowNamePopup] = useState(true);
  const [inputName, setInputName] = useState("");
  const [messages, setMessages] = useState<Message[]>([]);
  const [text, setText] = useState("");
  const [members, setMembers] = useState<string[]>([]);
  let socket = useRef<undefined | WebSocket>(undefined);

  const formatTime = (ts: number) => {
    const d = new Date(ts);
    const hh = String(d.getHours()).padStart(2, "0");
    const mm = String(d.getMinutes()).padStart(2, "0");
    return `${hh}:${mm}`;
  };

  function handleNameSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const trimmed = inputName.trim();
    if (!trimmed) return;

    setUserName(trimmed);
    setShowNamePopup(false);
    setMembers([trimmed]);
    socket.current = new WebSocket(`${URL}?name=${trimmed}`);
    socket.current.onopen = () => {
      console.log("Connected");
    };

    socket.current.onmessage = (event) => {
      const msg = JSON.parse(event.data);
      if (msg.type === "connect") {
        setMembers((prev) => [...prev, msg.name]);
        setMessages((prev) => [
          ...prev,
          {
            id: String(Date.now()),
            text: msg.members,
            ts: String(Date.now()),
          },
        ]);
      } else if (msg.type === "disconnect") {
        setMembers((prev) => prev.filter((e) => e != msg.name));
        setMessages((prev) => [
          ...prev,
          {
            id: String(Date.now()),
            text: msg.members,
            ts: String(Date.now()),
          },
        ]);
      } else if (msg.type === "publicMessage") {
        console.log(msg);
        setMessages((prev) => [
          ...prev,
          {
            id: msg?.message?.id || String(Date.now()),
            text: msg.message.text,
            sender: msg.message.sender,
            ts: msg?.message?.ts || String(Date.now()),
          },
        ]);
      }
      // else if (data.publicMessage) {
      //   setChatRows(oldArray => [...oldArray, <span><b>{data.publicMessage}</b></span>]);
      // } else if (data.privateMessage) {
      //   alert(data.privateMessage);
      // } else if (data.systemMessage) {
      //   setChatRows(oldArray => [...oldArray, <span><i>{data.systemMessage}</i></span>]);
      // }
    };

    socket.current.onclose = () => {
      console.log("Disconnected");
    };
  }

  function sendMessage() {
    if (!socket.current || socket.current.readyState !== WebSocket.OPEN) return;

    const t = text.trim();
    if (!t) return;

    const msg = {
      id: String(Date.now()),
      sender: userName,
      text: t,
      ts: String(Date.now()),
    };

    socket.current.send(
      JSON.stringify({
        action: "sendMessage",
        message: msg,
      })
    );

    setMessages((m) => [...m, msg]);
    setText("");
  }

  function handleKeyDown(e: KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  }

  useEffect(() => {
    if (userName && !socket.current) {
      socket.current = new WebSocket(`${URL}?name=${userName}`);
      socket.current.onopen = () => {
        console.log("Connected again");
      };
    }
    return () => {
      if (socket.current) {
        socket.current.onclose = () => {
          console.log("Disconnected");
        };
      }
    };
  }, [userName]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-zinc-100 p-4 font-thin">
      {showNamePopup ? (
        <div className="fixed inset-0 flex items-center justify-center z-40">
          <div className="bg-white rounded-xl shadow-lg max-w-md p-8">
            <h1 className="text-xl font-semibold text-black">
              Enter your name
            </h1>
            <p className="text-sm text-gray-500 mt-1">
              Enter your name to start chatting. This will be used to identify
            </p>
            <form onSubmit={handleNameSubmit} className="mt-4">
              <input
                type="text"
                autoFocus
                value={inputName}
                onChange={(e) => setInputName(e.target.value)}
                className="w-full border border-gray-200 rounded-md px-3 py-2 outline-green-500 placeholder-gray-400"
                placeholder="You name"
              />
              <button
                type="submit"
                className="block ml-auto px-4 py-1.5 rounded-full bg-gray-500 text-white font-medium cursor-pointer"
              >
                Continue
              </button>
            </form>
          </div>
        </div>
      ) : (
        <div className="w-full max-w-2xl h-[90vh] flex">
          <div className="h-full w-[10vw] max-[100px] bg-white rounded-md shadow-md flex flex-col">
            <div className="w-full h-[60px] flex items-center justify-center">
              <h1 className="text-green-400 font-semibold">Friends</h1>
            </div>
            <div className="flex items-center gap-y-1 flex-col overflow-y-auto flex-1">
              {members.map((e) => (
                <span key={e}>{e}</span>
              ))}
            </div>
          </div>

          <div className="size-full bg-white rounded-xl shadow-md flex flex-col overflow-hidden">
            <div className="flex items-center gap-3 px-4 py-3 border-b border-gray-200">
              <div className="size-10 rounded-full bg-[#075E54] flex items-center justify-center text-white font-semibold">
                R
              </div>
              <div className="flex-1">
                <div className="text-sm font-medium text-[#303030]">
                  Realtime group chat
                </div>
                <div className="text-xs text-green-500">
                  Someone is typing...
                </div>
              </div>
              <div className="text-sm text-gray-500">
                Signed in as
                <span className="ml-1 font-medium text-[#303030] capitalize">
                  {userName}
                </span>
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-zinc-100 flex flex-col">
              {messages.map((m) => {
                if (!m.sender) {
                  return (
                    <div key={m.id} className="flex justify-center">
                      <div className="max-w-[90%] px-2 py-1 rounded-[10px] text-sm leading-5 shadow-sm bg-gray text-[#303030] rounded-bl-2xl bg-gray-50">
                        <div className="wrap-break-word whitespace-pre-wrap">
                          {m.text}
                        </div>
                        <div className="flex justify-between items-center">
                          <div className="text-[11px] font-bold">
                            {m.sender}
                          </div>
                          <div className="text-[11px] text-gray-500 text-right">
                            {formatTime(Number(m.ts))}
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                }

                const mine = m.sender === userName;

                return (
                  <div
                    key={m.id}
                    className={`flex ${mine ? "justify-end" : "justify-start"}`}
                  >
                    <div
                      className={`max-w-[70%] p-3 my-2 rounded-[10px] text-sm leading-5 shadow-sm ${
                        mine
                          ? "bg-[#DCF8C6] text-[#303030] rounded-br-2xl"
                          : "bg-white text-[#303030] rounded-bl-2xl"
                      }`}
                    >
                      <div className="wrap-break-word whitespace-pre-wrap">
                        {m.text}
                      </div>
                      <div className="flex justify-between items-center mt-1 gap-10">
                        <div className="text-[11px] font-bold">{m.sender}</div>
                        <div className="text-[11px] text-gray-500 text-right">
                          {formatTime(Number(m.ts))}
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            <div className="px-4 py-3 border-t border-gray-200 bg-white">
              <div className="flex items-center justify-between gap-4 border border-gray-200 rounded-full">
                <textarea
                  rows={1}
                  value={text}
                  onChange={(e) => setText(e.target.value)}
                  onKeyDown={handleKeyDown}
                  placeholder="Type a message..."
                  className="w-full resize-none p-4 text-sm outline-none"
                />
                <button
                  onClick={sendMessage}
                  className="bg-green-500 text-white px-4 py-3 mr-2 rounded-full text-sm font-medium cursor-pointer"
                >
                  Send
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
