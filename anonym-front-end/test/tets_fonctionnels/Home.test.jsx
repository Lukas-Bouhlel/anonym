import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import Home from '../../src/pages/Home';
import { HelmetProvider } from 'react-helmet-async';
import sphereAnimation from '../../src/components/Animation/useSphereAnimation';
import userEvent from '@testing-library/user-event';

// Mock des éléments
jest.mock('../../src/components/Animation/useSphereAnimation', () => jest.fn());
jest.mock('../../src/assets/images/icons/google_play_logo.png', () => ({
  __esModule: true,
  default: 'google-play-logo.png',
}));
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

  test('should display the Android QR code dialog without a direct download link', async () => {
    const user = userEvent.setup();

    render(
      <HelmetProvider>
        <Home />
      </HelmetProvider>
    );

    await user.click(screen.getByRole('button', { name: /application android/i }));

    expect(screen.getByRole('dialog')).toBeInTheDocument();
    expect(screen.getByLabelText(/qr code de téléchargement android/i)).toBeInTheDocument();
    expect(screen.getByAltText(/logo google play/i)).toBeInTheDocument();
    expect(screen.queryByRole('link', { name: /télécharger l’apk/i })).not.toBeInTheDocument();
  });
});
