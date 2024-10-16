import { useForm } from 'react-hook-form';
import PropTypes from 'prop-types';
import { Modal, Button } from 'rsuite'; 
import { useMutation, useQueryClient } from '@tanstack/react-query';
import axios from 'axios';
import { useApi } from '../../context/ApiContext';

/**
 * Composant ChannelForm pour créer un nouveau canal.
 *
 * @param {Object} props - Les propriétés du composant.
 * @param {boolean} props.show - Indique si la modal doit être affichée.
 * @param {Function} props.onClose - Fonction appelée pour fermer la modal.
 * @returns {JSX.Element} - Le rendu du composant ChannelForm.
 */
const ChannelForm = ({ show, onClose }) => {
    const { api_url } = useApi();// Utilise le contexte pour obtenir l'URL de l'API
    const queryClient = useQueryClient();
    const { register, handleSubmit, formState: { errors }, reset } = useForm();

    /**
     * Appel API pour créer un canal.
     * Utilise useMutation pour gérer l'état de la requête.
     */
    const mutation = useMutation({
        mutationFn: async (newChannel) => {
            const response = await axios.post(`${api_url}/api/channels`, {
                name: newChannel.channelName,
                description: newChannel.description,
            }, { withCredentials: true });
            return response.data;
        },
        onSuccess: () => {
            queryClient.invalidateQueries('channels'); // Rafraîchir les canaux
            reset(); // Réinitialiser le formulaire après création
            onClose(); // Fermer la modal
        },
        onError: (error) => {
            console.error('Erreur lors de la création du canal :', error);
        }
    });

    /**
     * Gestion de la soumission du formulaire.
     *
     * @param {Object} data - Les données soumises du formulaire.
     */
    const onSubmit = (data) => {
        mutation.mutate(data); 
    };

    return (
        <div id='channelform'>
            <Modal open={show} onClose={onClose} size="xs">
                <Modal.Header>
                    <Modal.Title>Créer un nouveau canal</Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    <form onSubmit={handleSubmit(onSubmit)}>
                        <div className="form-group mb-3">
                            <label htmlFor="channelName" className='form-label'>Nom du canal</label>
                            <input aria-required="true" aria-label="Nom du canal" id="channelName" type="text" className={`form-control ${errors.channelName ? 'is-invalid' : ''}`}
                                {...register('channelName', { required: 'Le nom du canal est requis' })}
                            />
                            {errors.channelName && (
                                <div className="invalid-feedback">{errors.channelName.message}</div>
                            )}
                        </div>

                        <div className="form-group">
                            <label htmlFor="description" className='form-label'>Description</label>
                            <input
                                id="description"
                                type="text"
                                aria-required="true" 
                                aria-label="Description"
                                className={`form-control ${errors.description ? 'is-invalid' : ''}`}
                                {...register('description', { required: 'La description est requise' })}
                            />
                            {errors.description && (
                                <div className="invalid-feedback">{errors.description.message}</div>
                            )}
                        </div>
                    </form>
                </Modal.Body>
                <Modal.Footer>
                    <Button
                        onClick={handleSubmit(onSubmit)}
                        appearance="primary"
                        loading={mutation.isLoading} // Utilisation de mutation.isLoading pour l'état de soumission
                    >
                        {mutation.isLoading ? 'Création...' : 'Créer'}
                    </Button>
                    <Button onClick={onClose} appearance="subtle">
                        Annuler
                    </Button>
                </Modal.Footer>
                {mutation.isError && <div className="text-danger">Une erreur est survenue lors de la création du canal.</div>}
            </Modal>  
        </div>
    );
};

ChannelForm.propTypes = {
    show: PropTypes.bool.isRequired, 
    onClose: PropTypes.func.isRequired
};

export default ChannelForm;