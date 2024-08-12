import {useState} from 'react';
import Register from './Register/Register';
import Login from './Login/Login';
import { useAuth } from '../../context/AuthContext';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faXmark } from '@fortawesome/free-solid-svg-icons'

const Access = () => {
    const { isAnonymOpen, AnonymIsClose } = useAuth();
    const [statusAccess, setStatusAccess] = useState(false);

    const handleClick = (status) => {
        setStatusAccess(status);
    };

    return (
        <div id={`${isAnonymOpen ? 'container-access' : ''}`} className={`container-access ${statusAccess ? 'active' : ''}`}>
            <Register/>
            <Login/>
            <button className='close-popup' onClick={AnonymIsClose}><FontAwesomeIcon icon={faXmark}/></button>
            <div className="toggle-container-access">
                <div className="toggle">
                    <div className="toggle-panel toggle-left">
                        <h1 className='container-access-title'>Welcome Back!</h1>
                        <p>Enter your personal details to use all of site features</p>
                        <button onClick={() => handleClick(false)} className="hidden" id="login">Sign In</button>
                    </div>
                    <div className="toggle-panel toggle-right">
                        <h1 className='container-access-title'>Hello, Friend!</h1>
                        <p>Register with your personal details to use all of site features</p>
                        <button onClick={() => handleClick(true)} className="hidden" id="register">Sign Up</button>
                    </div>
                </div>
            </div>
        </div>
    )
}
export default Access;