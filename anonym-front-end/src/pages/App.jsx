import React, { useState } from "react";
import Sidebar from "../components/layout/Sidebar";
import { useUser } from '../context/UserContext';
import { useSocket } from "../context/SocketContext";
import logo from '../assets/images/logos/anonym-logo-white.svg';
import logoBuy from '../assets/images/logos/anonym-logo-green.svg';
import Friends from "./Friends";
import Shop from "../components/Shop/Shop";
import ChannelForm from "../components/Messages/ChannelForm";
import ChannelMessages from "../components/Messages/ChannelMessages";

const App = () => {
    const { user } = useUser();
    const { socket } = useSocket();
    const [page, setPage] = useState('friends');
    const [modalVisible, setModalVisible] = useState(false);
    const [channel, setChannel] = useState();

    return (
        <div id="app">
            <div className="navbar-logo-anonym">
                <img src={logo} alt='logo-anonym' />nonym
            </div>
            <ChannelForm show={modalVisible} onClose={() => setModalVisible(false)} />
            <div className="container-fluid container-app">
                <div className="row flex-nowrap container-app-content">
                    <Sidebar user={user} page={page} setPage={setPage} setModalVisible={setModalVisible} canal={channel} setChannel={setChannel} socket={socket}/>
                    <div className={`col ${page !== 'canal' ? 'app-container' : 'app-message'}`}>
                        {page === 'friends' ? (
                            <Friends/>
                        ) : page === 'shop' ? (
                            <Shop user={user} logo={logoBuy}/>
                        ) : page === 'channel' ? (  
                            <ChannelForm />
                        ): page === 'canal' && (  
                            <ChannelMessages user={user} socket={socket} channel={channel} page={page} setPage={setPage}/>
                        )}
                    </div>
                </div>
            </div>
        </div>
    )
}

export default App;