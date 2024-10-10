import { render, screen } from '@testing-library/react';
import { ApiProvider, useApi } from '../../src/context/ApiContext'; // Ajustez le chemin selon votre structure de fichiers

// Composant de test pour vérifier l'utilisation du contexte
const TestComponent = () => {
    const { api_url } = useApi();
    return <div data-testid="api-url">{api_url}</div>; // Utilisation d'un testid pour rendre l'élément identifiable
};

describe('ApiContext', () => {
    beforeAll(() => {
        process.env.VITE_API_URL = 'http://mockapi.com'; // Remplacez par l'URL que vous attendez
    });

    test('devrait fournir l\'URL de l\'API via le contexte', () => {
        render(
            <ApiProvider>
                <TestComponent />
            </ApiProvider>
        );

        // Vérifiez que l'URL de l'API est correctement fournie
        const apiUrlElement = screen.getByTestId('api-url');
        expect(apiUrlElement).toBeInTheDocument(); // Vérifiez que l'élément est présent
        expect(apiUrlElement).toHaveTextContent('http://mockapi.com'); // Vérifiez que le texte de l'élément est correct
    });
});