import React, { useState } from "react";
import axios from "axios";
import { Modal, Button } from 'rsuite';
import { useApi } from "../../context/ApiContext";

const Users = ({ users, refetch }) => {
    const data = users.data || []; // Définit data par défaut à un tableau vide
    const { api_url } = useApi();
    const [selectedUser, setSelectedUser] = useState({}); // Initialise selectedUser à un objet vide
    const [open, setOpen] = useState(false);
    const [createOpen, setCreateOpen] = useState(false);
    const [errorMessage, setErrorMessage] = useState("");
    const [showDeleteConfirmation, setShowDeleteConfirmation] = useState(false);
    const [newUser, setNewUser] = useState({
        username: '',
        email: '',
        password: '',
        roles: 'USER'
    });

    const handleOpen = (user) => {
        setSelectedUser(user);
        setOpen(true);
    };

    const handleClose = () => {
        setSelectedUser({}); // Réinitialise selectedUser à un objet vide
        setOpen(false);
        setShowDeleteConfirmation(false);
        setErrorMessage("");
        setNewUser({ username: '', email: '', password: '', roles: 'USER' }); 
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        const formData = new FormData();
        const jsonData = {
            username: selectedUser.username,
            email: selectedUser.email,
            roles: selectedUser.roles
        };
        formData.append('datas', JSON.stringify(jsonData));

        try {
            const response = await axios.put(`${api_url}/api/admin/users/${selectedUser.id}`, formData, {
                withCredentials: true,
                headers: {
                    'Content-Type': 'multipart/form-data',
                }
            });

            if (response.status === 200) {
                handleClose();
                refetch();
            }
        } catch (error) {
            setErrorMessage(error.response?.data?.message || "Une erreur est survenue.");
        }
    };

    const handleDeleteAccount = async () => {
        try {
            await axios.delete(`${api_url}/api/admin/users/${selectedUser.id}`, {
                withCredentials: true
            });
            handleClose();
            refetch();
        } catch (error) {
            console.error("Erreur lors de la suppression du compte:", error);
            setErrorMessage(error.response?.data?.message || "Une erreur est survenue lors de la suppression.");
        }
    };

    const handleCreateAccount = async (e) => {
        e.preventDefault(); 
        const formData = new FormData();
        formData.append('datas', JSON.stringify(newUser)); 
    
        try {
            await axios.post(`${api_url}/api/admin/users`, formData, {
                withCredentials: true
            });
            setCreateOpen(false)
            refetch();
        } catch (error) {
            console.error("Erreur lors de la création du compte:", error);
            setErrorMessage(error.response?.data?.message || "Une erreur est survenue lors de la création.");
        }
    };
    

    const handleChange = (e) => {
        const { name, value } = e.target;
    
        if (createOpen) {
            setNewUser({
                ...newUser,
                [name]: value
            });
        } else {
            setSelectedUser({
                ...selectedUser,
                [name]: value
            });
        }
    };
    

    return (
        <div className="content-admin-container-item">
            <div className="content-admin-container-item-head">
                <h1>Utilisateurs</h1>
                <Button onClick={() => setCreateOpen(true)} className="mb-3">Créer un utilisateur</Button>
            </div>
            {users && data.length > 0 ? ( // Vérifie que data a des utilisateurs
                <div className="table-responsive-scroll">
                    <table className="table align-middle mb-0 bg-white">
                        <thead className="bg-light">
                            <tr>
                                <th>id</th>
                                <th>avatar</th>
                                <th>username</th>
                                <th>email</th>
                                <th>createdAt</th>
                                <th>updatedAt</th>
                                <th>Roles</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {data.map((user, index) => (
                                <tr key={index}>
                                    <td>
                                        <p className="fw-normal mb-1">{user.id}</p>
                                    </td>
                                    <td>
                                        <div className="d-flex align-items-center">
                                            <img src={user.avatar} alt="" className="rounded-circle" />
                                        </div>
                                    </td>
                                    <td>
                                        <p className="fw-normal">{user.username}</p>
                                    </td>
                                    <td>
                                        <p className="text-muted">{user.email}</p>
                                    </td>
                                    <td>
                                        <p className="fw-normal">{new Date(user.createdAt).toLocaleDateString()}</p>
                                    </td>
                                    <td>
                                        <p className="text-muted">{new Date(user.updatedAt).toLocaleDateString()}</p>
                                    </td>
                                    <td>
                                        <span className="fw-normal">{user.roles}</span>
                                    </td>
                                    <td>
                                        <button onClick={() => handleOpen(user)} type="button" className="btn btn-link btn-sm btn-rounded">
                                            Edit
                                        </button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                    {/* Modal pour éditer l'utilisateur */}
                    <Modal open={open} onClose={handleClose}>
                        <Modal.Header>
                            <Modal.Title>Editer l'utilisateur</Modal.Title>
                        </Modal.Header>
                        <Modal.Body>
                            {errorMessage && <div className="error-message" style={{ color: "red" }}>{errorMessage}</div>}
                            <form onSubmit={handleSubmit}>
                                <div className="mb-3">
                                    <label htmlFor="username" className="form-label">Nom d'utilisateur</label>
                                    <input type="text" className="form-control" id="username" name="username" value={selectedUser.username || ''} onChange={handleChange} /> {/* Gère le cas où selectedUser.username est indéfini */}
                                </div>
                                <div className="mb-3">
                                    <label htmlFor="email" className="form-label">Email</label>
                                    <input type="email" className="form-control" id="email" name="email" value={selectedUser.email || ''} onChange={handleChange} /> {/* Gère le cas où selectedUser.email est indéfini */}
                                </div>
                                <div className="mb-3">
                                    <label htmlFor="roles" className="form-label">Rôles</label>
                                    <select
                                        className="form-select"
                                        id="roles"
                                        name="roles"
                                        value={selectedUser.roles || 'USER'} // Utilise 'USER' par défaut si selectedUser.roles est indéfini
                                        onChange={handleChange}
                                    >
                                        <option value="USER">USER</option>
                                        <option value="ADMIN">ADMIN</option>
                                        <option value="SUPER_ADMIN">SUPER_ADMIN</option>
                                    </select>
                                </div>
                                <Modal.Footer>
                                    <Button onClick={handleClose} appearance="subtle">Annuler</Button>
                                    <Button type="submit" className="btn btn-primary">Enregistrer</Button>
                                    <Button onClick={() => setShowDeleteConfirmation(true)}>Supprimer le compte</Button>
                                </Modal.Footer>
                            </form>
                        </Modal.Body>
                    </Modal>

                    {/* Modal de création d'utilisateur */}
                    <Modal open={createOpen} onClose={() => setCreateOpen(false)}>
                        <Modal.Header>
                            <Modal.Title>Créer un nouvel utilisateur</Modal.Title>
                        </Modal.Header>
                        <Modal.Body>
                            {errorMessage && <div className="error-message" style={{ color: "red" }}>{errorMessage}</div>}
                            <form onSubmit={handleCreateAccount}>
                                <div className="mb-3">
                                    <label htmlFor="username" className="form-label">Nom d'utilisateur</label>
                                    <input type="text" className="form-control" id="username" name="username" value={newUser.username} onChange={handleChange} required />
                                </div>
                                <div className="mb-3">
                                    <label htmlFor="email" className="form-label">Email</label>
                                    <input type="email" className="form-control" id="email" name="email" value={newUser.email} onChange={handleChange} required />
                                </div>
                                <div className="mb-3">
                                    <label htmlFor="password" className="form-label">Mot de passe</label>
                                    <input type="password" className="form-control" id="password" name="password" value={newUser.password} onChange={handleChange} required />
                                </div>
                                <div className="mb-3">
                                    <label htmlFor="roles" className="form-label">Rôles</label>
                                    <select 
                                        className="form-select" 
                                        id="roles" 
                                        name="roles" 
                                        value={newUser.roles} 
                                        onChange={handleChange}
                                    >
                                        <option value="USER">USER</option>
                                        <option value="ADMIN">ADMIN</option>
                                        <option value="SUPER_ADMIN">SUPER_ADMIN</option>
                                    </select>
                                </div>
                                <Modal.Footer>
                                    <Button onClick={() => setCreateOpen(false)} appearance="subtle">Annuler</Button>
                                    <Button type="submit" className="btn btn-primary">Créer</Button>
                                </Modal.Footer>
                            </form>
                        </Modal.Body>
                    </Modal>

                    {/* Modal de confirmation de suppression */}
                    {showDeleteConfirmation && (
                        <Modal open={showDeleteConfirmation} onClose={() => setShowDeleteConfirmation(false)}>
                            <Modal.Header>
                                <Modal.Title>Confirmation de Suppression</Modal.Title>
                            </Modal.Header>
                            <Modal.Body>
                                Êtes-vous sûr de vouloir supprimer ce compte ? Cette action est irréversible.
                            </Modal.Body>
                            <Modal.Footer>
                                <Button onClick={() => setShowDeleteConfirmation(false)} appearance="subtle">Annuler</Button>
                                <Button onClick={handleDeleteAccount}>Supprimer</Button>
                            </Modal.Footer>
                        </Modal>
                    )}
                </div>
            ) : (
                <p>Chargement...</p>
            )}
        </div>
    );
}

export default Users;