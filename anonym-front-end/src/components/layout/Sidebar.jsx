import React from "react";
import { Link } from "react-router-dom";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faUser, faShop, faGear } from '@fortawesome/free-solid-svg-icons';
import { Tooltip, Whisper } from 'rsuite';

const Sidebar = ({ user }) => {
    const tooltip = (
        <Tooltip>
            Paramètres utilisateur
        </Tooltip>
    );
    return (
        <>
            <div className="col-auto px-0 sidebar">
                <div className="d-flex flex-column align-items-center align-items-sm-start text-white min-vh-100 sidebar-content">
                    <ul className="nav px-3 nav-pills flex-column mb-sm-auto mb-0 align-items-center align-items-sm-start" id="menu">
                        <li className="nav-item">
                            <Link to="/app" className="nav-link align-middle px-0 link-sidebar">
                                <span className="ms-1 d-none d-sm-inline"><FontAwesomeIcon icon={faUser}/> Amis</span>
                            </Link>
                        </li>
                        <li className="nav-item">
                            <Link to="/shop" className="nav-link align-middle px-0 link-sidebar">
                                <span className="ms-1 d-none d-sm-inline"><FontAwesomeIcon icon={faShop}/> Boutique</span>
                            </Link>
                        </li>
                        <li>
                            <a href="#submenu1" data-bs-toggle="collapse" className="nav-link px-0 align-middle link-sidebar">
                                <span className="ms-1 d-none d-sm-inline">Messages privés +</span> </a>
                            <ul className="collapse show nav flex-column ms-1" id="submenu1" data-bs-parent="#menu">
                                <li className="w-100">
                                    {/* <a href="#" className="nav-link px-0 link-sidebar"> <span className="d-none d-sm-inline">Item</span> 1 </a> */}
                                </li>
                            </ul>
                        </li>
                    </ul>
                    <hr />
                    <div className="pb-2 px-sm-2 sidebar-profile">
                        <div className="d-flex align-items-center sidebar-profile-content" aria-expanded="false">
                            <div>
                                <img src={`${user.avatar}`} alt="hugenerd" width="30" height="30" className="rounded-circle" />
                                <span className="d-none d-sm-inline mx-1">
                                    <strong>{user.username}</strong>
                                </span>
                            </div>
                            <Whisper placement="top" controlId="control-id-hover" trigger="hover" speaker={tooltip}>
                                <Link to="/profile" className="open-params">
                                    <FontAwesomeIcon icon={faGear}/>
                                </Link>
                            </Whisper>
                        </div>
                    </div>
                </div>
            </div>
        </>
    )
}

export default Sidebar;