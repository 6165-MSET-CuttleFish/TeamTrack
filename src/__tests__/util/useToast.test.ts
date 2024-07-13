typescript
import { renderHook } from '@testing-library/react-hooks';
import { useToast } from '../useToast';
import { ToastProvider } from '../ToastProvider';

describe('useToast', () => {
  it('should render a toast message', () => {
    const { result } = renderHook(() => useToast(), {
      wrapper: ({ children }) => (
        <ToastProvider>{children}</ToastProvider>
      ),
    });

    expect(result.current.show).toBeDefined();
    expect(result.current.hide).toBeDefined();
  });

  it('should show a toast message', () => {
    const { result } = renderHook(() => useToast(), {
      wrapper: ({ children }) => (
        <ToastProvider>{children}</ToastProvider>
      ),
    });

    result.current.show('Test message');

    expect(result.current.isVisible).toBe(true);
  });

  it('should hide a toast message', () => {
    const { result } = renderHook(() => useToast(), {
      wrapper: ({ children }) => (
        <ToastProvider>{children}</ToastProvider>
      ),
    });

    result.current.show('Test message');
    result.current.hide();

    expect(result.current.isVisible).toBe(false);
  });
});