import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom'; // Pour des assertions supplémentaires comme toBeInTheDocument()
import Home from '../../src/pages/Home'; // Le chemin vers ton composant Home
import sphereAnimation from '../../src/components/Animation/useSphereAnimation';

// On mock l'animation et l'icône SVG
jest.mock('../../src/components/Animation/useSphereAnimation'); // Mock de l'animation
jest.mock('../../src/assets/images/icons/sphere.svg?react', () => {
  const SphereSvg = () => <svg data-testid="sphere-svg" />;
  SphereSvg.displayName = 'SphereSvg'; // Assign a display name
  return SphereSvg; // Return the named component
}); // Mock de l'icône SVG

describe('Home Page', () => {
  test('should call sphereAnimation when rendered', () => {
    // Rendre le composant
    render(<Home />);
    
    // Vérifier que sphereAnimation a été appelé une fois
    expect(sphereAnimation).toHaveBeenCalled();
  });

  test('should render the title and paragraph', () => {
    // Rendre le composant
    render(<Home />);

    // Vérifier si le titre est affiché
    const titleElement = screen.getByText('Le réseau social...');
    expect(titleElement).toBeInTheDocument();

    // Vérifier si le paragraphe est affiché
    const paragraphElement = screen.getByText(/qui protège tes données/i);
    expect(paragraphElement).toBeInTheDocument();
  });

  test('should render the SphereSvg icon', () => {
    // Rendre le composant
    render(<Home />);

    // Vérifier que l'icône SVG est affichée
    const svgElement = screen.getByTestId('sphere-svg');
    expect(svgElement).toBeInTheDocument();
  });
});