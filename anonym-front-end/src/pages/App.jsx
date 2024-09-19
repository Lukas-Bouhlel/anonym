import React from "react";
import Sidebar from "../components/layout/Sidebar";
import { useUser } from '../context/UserContext';
import logo from '../assets/images/logos/anonym-logo-white.svg';
import Friends from "./Friends";

const App = () => {
    const { user } = useUser();
    return (
        <div id="app">
            <div className="navbar-logo-anonym">
                <img src={logo} alt='logo-anonym' />nonym
            </div>
            <div className="container-fluid">
                <div className="row flex-nowrap">
                    <Sidebar user={user} />
                    <div className="col app-container">
                        <Friends/>
                    </div>
                </div>
            </div>
        </div>
    )
}

export default App;