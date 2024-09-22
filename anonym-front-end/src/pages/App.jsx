import React, { useState } from "react";
import Sidebar from "../components/layout/Sidebar";
import { useUser } from '../context/UserContext';
import logo from '../assets/images/logos/anonym-logo-white.svg';
import logoBuy from '../assets/images/logos/anonym-logo-green.svg';
import Friends from "./Friends";
import Shop from "../components/Shop/Shop";

const App = () => {
    const { user } = useUser();
    const [page, setPage] = useState('friends');

    return (
        <div id="app">
            <div className="navbar-logo-anonym">
                <img src={logo} alt='logo-anonym' />nonym
            </div>
            <div className="container-fluid">
                <div className="row flex-nowrap">
                    <Sidebar user={user} page={page} setPage={setPage}/>
                    <div className="col app-container">
                        {page === 'friends' ? (
                            <Friends/>
                        ) : page === 'shop' && (
                            <Shop user={user} logo={logoBuy}/>
                        )}
                    </div>
                </div>
            </div>
        </div>
    )
}

export default App;