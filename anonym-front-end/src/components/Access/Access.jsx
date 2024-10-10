import {useEffect, useState} from 'react';
import Register from './Register/Register';
import Login from './Login/Login';
import { useAuth } from '../../context/AuthContext';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faXmark } from '@fortawesome/free-solid-svg-icons';
import { useLocation  } from 'react-router-dom';
import PasswordReset from './Reset/PasswordReset';

const Access = () => {
    const { isAnonymOpen, AnonymIsClose } = useAuth();
    const [statusAccess, setStatusAccess] = useState(false);
    const [statusForm, setStatusForm] = useState('login');
    const location = useLocation();

    useEffect(() => {
        if (isAnonymOpen) {
            AnonymIsClose();
        }
    }, [location]); 

    const handleClick = (status) => {
        setStatusAccess(status);
    };

    return (
        <div id={`${isAnonymOpen ? 'container-access' : ''}`} className={`container-access ${statusAccess ? 'active' : ''}`}>
            <Register setStatusAccess={setStatusAccess}/>
            {statusForm === 'login' ? (
                <Login setStatusForm={setStatusForm} setStatusAccess={setStatusAccess}/>
            ) : (
                <PasswordReset setStatusForm={setStatusForm}/>
            )}
            <button className='close-popup' onClick={AnonymIsClose}><FontAwesomeIcon icon={faXmark}/></button>
            <div className="toggle-container-access">
                <div className="toggle">
                    <div className="toggle-panel toggle-left">
                        <h1 className='container-access-title'>De retour !</h1>
                        <p>Entrez vos informations personnelles pour utiliser toutes les fonctionnalités du site</p>
                        <button onClick={() => handleClick(false)} className="hidden" id="login">Se connecter</button>
                    </div>
                    <div className="toggle-panel toggle-right">
                        <h1 className='container-access-title'>Bonjour mon ami!</h1>
                        <p>Inscrivez-vous avec vos informations personnelles pour utiliser toutes les fonctionnalités du site</p>
                        <button onClick={() => handleClick(true)} className="hidden" id="register">S&apos;inscrire</button>
                    </div>
                </div>
            </div>
        </div>
    )
}
export default Access;