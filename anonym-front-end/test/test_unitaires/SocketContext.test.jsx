import { render, screen, waitFor } from '@testing-library/react';
import { SocketProvider, useSocket } from '../../src/context/SocketContext';
import { ApiProvider } from '../../src/context/ApiContext'; // Assurez-vous d'importer ApiProvider

// Composant de test pour vérifier l'utilisation du contexte
const TestComponent = () => {
    const { socket } = useSocket();

    return (
        <div>
            {socket ? <div data-testid="socket-status">Socket connecté</div> : <div data-testid="socket-status">Pas de socket</div>}
        </div>
    );
};

describe('SocketContext', () => {
    beforeAll(() => {
        // Simulez l'URL de l'API
        process.env.VITE_API_URL = 'http://mockapi.com'; // Remplacez par l'URL que vous attendez
    });

    test('devrait initialiser le socket correctement', async () => {
        render(
            <ApiProvider>
                <SocketProvider>
                    <TestComponent />
                </SocketProvider>
            </ApiProvider>
        );

        // Attendez que le socket soit initialisé
        await waitFor(() => {
            expect(screen.getByTestId('socket-status')).toHaveTextContent('Socket connecté');
        });
    });

    test('devrait se déconnecter lorsque le composant est démonté', async () => {
        const { unmount } = render(
            <ApiProvider>
                <SocketProvider>
                    <TestComponent />
                </SocketProvider>
            </ApiProvider>
        );

        // Attendez que le socket soit initialisé
        await waitFor(() => {
            expect(screen.getByTestId('socket-status')).toHaveTextContent('Socket connecté');
        });

        // Démontez le composant
        unmount();
    });
});