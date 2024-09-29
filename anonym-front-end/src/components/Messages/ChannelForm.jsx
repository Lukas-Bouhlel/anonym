import React from 'react';
import { useForm } from 'react-hook-form';
import { Modal, Button } from 'rsuite'; 
import { useMutation, useQueryClient } from '@tanstack/react-query';
import axios from 'axios';
import { useApi } from '../../context/ApiContext';

const ChannelForm = ({ show, onClose }) => {
    const { api_url } = useApi();
    const queryClient = useQueryClient();
    const { register, handleSubmit, formState: { errors, isSubmitting }, reset } = useForm();

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

    // Gestion de la soumission du formulaire
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
                            <input id="channelName" type="text" className={`form-control ${errors.channelName ? 'is-invalid' : ''}`}
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

export default ChannelForm;