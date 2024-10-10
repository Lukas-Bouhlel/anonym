import { render, screen, fireEvent } from '@testing-library/react';
import { AuthProvider, useAuth } from '../../src/context/AuthContext'; // Ajustez le chemin selon votre structure de fichiers

// Composant de test pour vérifier l'utilisation du contexte
const TestComponent = () => {
    const { isAnonymOpen, AnonymIsOpen, AnonymIsClose } = useAuth();
    return (
        <div>
            <div data-testid="anonym-status">
                {isAnonymOpen ? 'Anonyme ouvert' : 'Anonyme fermé'}
            </div>
            <button onClick={AnonymIsOpen}>Ouvrir Anonyme</button>
            <button onClick={AnonymIsClose}>Fermer Anonyme</button>
        </div>
    );
};

describe('AuthContext', () => {
    test('devrait initialiser le contexte correctement', () => {
        render(
            <AuthProvider>
                <TestComponent />
            </AuthProvider>
        );

        // Vérifiez que l'état initial est 'Anonyme fermé'
        const statusElement = screen.getByTestId('anonym-status');
        expect(statusElement).toHaveTextContent('Anonyme fermé');
    });

    test('devrait ouvrir l\'anonymat lorsque le bouton est cliqué', () => {
        render(
            <AuthProvider>
                <TestComponent />
            </AuthProvider>
        );

        // Trouvez le bouton pour ouvrir l'anonymat et cliquez dessus
        const openButton = screen.getByText('Ouvrir Anonyme');
        fireEvent.click(openButton);

        // Vérifiez que l'état est maintenant 'Anonyme ouvert'
        const statusElement = screen.getByTestId('anonym-status');
        expect(statusElement).toHaveTextContent('Anonyme ouvert');
    });

    test('devrait fermer l\'anonymat lorsque le bouton est cliqué', () => {
        render(
            <AuthProvider>
                <TestComponent />
            </AuthProvider>
        );

        // Ouvrir d'abord l'anonymat
        fireEvent.click(screen.getByText('Ouvrir Anonyme'));

        // Maintenant, fermez l'anonymat
        const closeButton = screen.getByText('Fermer Anonyme');
        fireEvent.click(closeButton);

        // Vérifiez que l'état est maintenant 'Anonyme fermé'
        const statusElement = screen.getByTestId('anonym-status');
        expect(statusElement).toHaveTextContent('Anonyme fermé');
    });
});
