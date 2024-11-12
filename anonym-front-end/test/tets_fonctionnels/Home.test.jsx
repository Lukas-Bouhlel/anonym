import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import Home from '../../src/pages/Home';
import { HelmetProvider } from 'react-helmet-async';
import sphereAnimation from '../../src/components/Animation/useSphereAnimation';

// Mock des éléments
jest.mock('../../src/components/Animation/useSphereAnimation', () => jest.fn());
jest.mock('../../src/assets/images/icons/sphere.svg?react', () => {
  const SphereSvg = () => <svg data-testid="sphere-svg" />;
  SphereSvg.displayName = 'SphereSvg';
  return SphereSvg;
});

describe('Home Page', () => {
  test('should call sphereAnimation when rendered', () => {
    // Rendre le composant avec le wrapper HelmetProvider
    render(
      <HelmetProvider>
        <Home />
      </HelmetProvider>
    );

    // Vérifier que sphereAnimation a été appelé une fois
    expect(sphereAnimation).toHaveBeenCalled();
  });

  test('should render the title and paragraph', () => {
    render(
      <HelmetProvider>
        <Home />
      </HelmetProvider>
    );

    const titleElement = screen.getByText('Le réseau social...');
    expect(titleElement).toBeInTheDocument();

    const paragraphElement = screen.getByText(/qui protège tes données/i);
    expect(paragraphElement).toBeInTheDocument();
  });

  test('should render the SphereSvg icon', () => {
    render(
      <HelmetProvider>
        <Home />
      </HelmetProvider>
    );

    const svgElement = screen.getByTestId('sphere-svg');
    expect(svgElement).toBeInTheDocument();
  });
});
