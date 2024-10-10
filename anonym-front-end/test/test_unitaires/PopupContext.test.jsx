import { render, screen, fireEvent } from '@testing-library/react';
import { PopupProvider, usePopup } from '../../src/context/PopupContext'; // Ajustez le chemin selon votre structure de fichiers

// Composant de test pour vérifier l'utilisation du contexte
const TestComponent = () => {
    const { openPopup, setOpenPopup, textPopup, setTextPopup, state, setState } = usePopup();
    
    return (
        <div>
            <div data-testid="popup-status">
                {openPopup ? textPopup : 'Popup fermé'}
            </div>
            <button onClick={() => { setTextPopup('Popup ouvert !'); setOpenPopup(true); }}>Ouvrir Popup</button>
            <button onClick={() => setOpenPopup(false)}>Fermer Popup</button>
            <button onClick={() => setState('État modifié')}>Modifier État</button>
            <div data-testid="state-status">{state}</div>
        </div>
    );
};

describe('PopupContext', () => {
    test('devrait initialiser le contexte correctement', () => {
        render(
            <PopupProvider>
                <TestComponent />
            </PopupProvider>
        );

        // Vérifiez que l'état initial est 'Popup fermé'
        const statusElement = screen.getByTestId('popup-status');
        expect(statusElement).toHaveTextContent('Popup fermé');
    });

    test('devrait ouvrir le popup lorsque le bouton est cliqué', () => {
        render(
            <PopupProvider>
                <TestComponent />
            </PopupProvider>
        );

        // Trouvez le bouton pour ouvrir le popup et cliquez dessus
        const openButton = screen.getByText('Ouvrir Popup');
        fireEvent.click(openButton);

        // Vérifiez que le texte du popup est correct
        const statusElement = screen.getByTestId('popup-status');
        expect(statusElement).toHaveTextContent('Popup ouvert !');
    });

    test('devrait fermer le popup lorsque le bouton est cliqué', () => {
        render(
            <PopupProvider>
                <TestComponent />
            </PopupProvider>
        );

        // Ouvrir d'abord le popup
        fireEvent.click(screen.getByText('Ouvrir Popup'));

        // Maintenant, fermez le popup
        const closeButton = screen.getByText('Fermer Popup');
        fireEvent.click(closeButton);

        // Vérifiez que l'état est maintenant 'Popup fermé'
        const statusElement = screen.getByTestId('popup-status');
        expect(statusElement).toHaveTextContent('Popup fermé');
    });

    test('devrait modifier l\'état lorsque le bouton est cliqué', () => {
        render(
            <PopupProvider>
                <TestComponent />
            </PopupProvider>
        );

        // Modifier l'état
        fireEvent.click(screen.getByText('Modifier État'));

        // Vérifiez que l'état a été modifié
        const stateStatusElement = screen.getByTestId('state-status');
        expect(stateStatusElement).toHaveTextContent('État modifié');
    });
});
